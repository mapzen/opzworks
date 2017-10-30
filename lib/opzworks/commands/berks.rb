# frozen_string_literal: true

require 'aws-sdk'
require 'trollop'
require 'opzworks'
require 'rainbow/ext/string'

require_relative 'include/run_local'
require_relative 'include/populate_stack'
require_relative 'include/manage_berks_repos'
require_relative 'include/wait_for_deployment'
require_relative 'include/rolling_deployment'

module OpzWorks
  class Commands
    class BERKS
      def self.banner
        'Build the stack berkshelf'
      end

      def self.run config, command_options

        if config.aws_credentials_path
          aws_credentials_provider = Aws::Credentials.new(config.aws_access_key, config.aws_secret_access_key)
          opsworks = Aws::OpsWorks::Client.new(region: config.aws_region, credentials: aws_credentials_provider)
        else
          aws_credentials_provider = Aws::SharedCredentials.new(profile_name: config.aws_profile)
          opsworks = Aws::OpsWorks::Client.new(region: config.aws_region, profile: config.aws_profile)
        end

        s3 = Aws::S3::Resource.new(region: config.aws_region, credentials: aws_credentials_provider)
        s3_client = Aws::S3::Client.new(region: config.aws_region, credentials: aws_credentials_provider)

        response = opsworks.describe_stacks

        # loops over inputs
        ARGV.each do |stack|

          var = populate_stack(stack, response)
          next if var == false
          hash = {
            'CHEF VERSION:' => @chef_version,
            'STACK ID:'     => @stack_id,
            'S3 PATH:'      => @s3_path,
            'S3 URL:'       => @s3_source_url,
            'BRANCH:'       => config.chef_branch
          }

          STDERR.puts "\n"
          STDERR.puts '-------------------------------'
          hash.each { |k, v| STDERR.printf("%-25s %-25s\n", k.foreground(:green), v.foreground(:red)) }
          STDERR.puts '-------------------------------'

          STDERR.puts "\n"
          var = manage_berks_repos(config)

          next if var == false
          next if command_options[:clone] == true

          time             = Time.new.utc.strftime('%FT%TZ')
          berks_cook_path  = config.berks_path || '/tmp'
          cook_path        = "#{berks_cook_path}/tmp-#{config.chef_branch}"
          if !config.berks_tarball_base_name.nil?
            cookbook_tarball = config.berks_tarball_base_name + '.tgz'
          else
            cookbook_tarball = 'cookbooks.tgz'
          end

          cookbook_upload  = cook_path + '/' "#{cookbook_tarball}"
          s3_bucket        = config.berks_s3_bucket || 'opzworks'

          FileUtils.mkdir_p(cook_path) unless File.exist?(cook_path)

          # berks
          #
          unless File.exist?("#{@target_path}/Berksfile.lock")
            STDERR.puts "\nNo Berksfile.lock, running berks install before packaging".foreground(:blue)
            run_local <<-BASH
              cd #{@target_path}
              berks install
              git add Berksfile.lock
            BASH
          end

          if command_options[:update]
            if command_options[:cookbooks].nil?
              STDERR.puts "\nUpdating the berkshelf".foreground(:blue)
              run_local <<-BASH
                cd #{@target_path}
                berks update
              BASH
            else
              STDERR.puts "\nUpdating the berkshelf for cookbook(s): ".foreground(:blue) + command_options[:cookbooks].join(', ').to_s.foreground(:green)
              run_local <<-BASH
                cd #{@target_path}
                berks update #{command_options[:cookbooks].join(' ')}
              BASH
            end
          else
            STDERR.puts "\nNot running berks update".foreground(:blue)
          end

          STDERR.puts "\nPackaging the berkshelf".foreground(:blue)
          run_local <<-BASH
            cd #{@target_path}
            berks package #{cook_path}/#{cookbook_tarball}
          BASH

          # backup previous if it exists
          #
          STDERR.puts "\nBackup".foreground(:blue)
          begin
            s3_client.head_object(
              bucket: s3_bucket,
              key: "#{@s3_path}/#{cookbook_tarball}"
            )
          rescue Aws::S3::Errors::ServiceError
            STDERR.puts "\tNo existing #{cookbook_tarball} in #{s3_bucket}/#{@s3_path} to backup, continuing...".foreground(:yellow)
          else
            STDERR.puts "\tBacking up existing #{cookbook_tarball} to #{@s3_path}/#{cookbook_tarball}-#{time}".foreground(:green)
            begin
              s3_client.copy_object(
                key: "#{@s3_path}/#{cookbook_tarball}-#{time}",
                bucket: s3_bucket,
                copy_source: "#{s3_bucket}/#{@s3_path}/#{cookbook_tarball}"
              )
            rescue Aws::S3::Errors::ServiceError => e
              STDERR.puts "\tCaught exception trying to backup existing #{cookbook_tarball} in #{s3_bucket}:".foreground(:red)
              STDERR.puts "\t\t#{e}"
              abort
            end
          end

          begin
            cull = s3_client.list_objects(
              bucket: s3_bucket,
              prefix: "#{@s3_path}/#{cookbook_tarball}-"
            )
          rescue Aws::S3::Errors::ServiceError => e
            STDERR.puts "\tCaught exception trying to list backups in #{s3_bucket}:".foreground(:red)
            STDERR.puts "\t\t#{e}"
          else
            backup_arr = []
            cull.contents.each { |k| backup_arr << k.key }
            backup_arr.pop(5) # keep last 5 backups

            unless backup_arr.empty?
              delete_arr = []
              until backup_arr.empty?
                STDERR.puts "\tAdding backup #{backup_arr[0]} to the cull list".foreground(:green)
                delete_arr << backup_arr.pop

                arr_of_hash = []
                delete_arr.each { |i| arr_of_hash << { 'key': i } }

                STDERR.puts "\tCulling old backups".foreground(:green)
                begin
                  s3_client.delete_objects(
                    bucket: s3_bucket,
                    delete: { objects: arr_of_hash }
                  )
                rescue Aws::S3::Errors::ServiceError => e
                  STDERR.puts "\tCaught exception trying to delete backups in #{s3_bucket}:".foreground(:red)
                  STDERR.puts "\t\t#{e}"
                end
              end
            end
          end

          # upload
          STDERR.puts "\nUploading to S3".foreground(:blue)
          begin
            obj = s3.bucket(s3_bucket).object("#{@s3_path}/#{cookbook_tarball}")
            obj.upload_file(cookbook_upload)
          rescue Aws::S3::Errors::ServiceError => e
            STDERR.puts "\tCaught exception while uploading to S3 bucket #{s3_bucket}:".foreground(:red)
            STDERR.puts "\t\t#{e}"
            STDERR.puts "\t\t\nCleaning up before exiting".foreground(:blue)

            FileUtils.rm_rf(cook_path)
            abort
          else
            STDERR.puts "\tCompleted successful upload of #{@s3_path}/#{cookbook_tarball} to #{s3_bucket}!".foreground(:green)
          end

          # cleanup
          #
          STDERR.puts "\nCleaning up".foreground(:blue)
          FileUtils.rm_rf(cook_path)
          STDERR.puts "\tDone!".foreground(:green)

          # update remote cookbooks
          #
          if command_options[:ucc] == true
            STDERR.puts "\nTriggering update_custom_cookbooks for remote stack (#{@stack_id})".foreground(:blue)

            hash = {}
            hash[:comment]  = 'update custom cookbooks'
            hash[:stack_id] = @stack_id
            hash[:command]  = { name: 'update_custom_cookbooks' }

            begin
              resp = opsworks.create_deployment(hash)
              deployment_id = resp.deployment_id
            rescue Aws::OpsWorks::Errors::ServiceError => e
              STDERR.puts "\tCaught error while attempting to trigger deployment: ".foreground(:red)
              STDERR.puts "\t\t#{e}"
            else
              STDERR.puts "\tDone!".foreground(:green)
              STDERR.puts "\n"
            end
          else
            STDERR.puts 'Update custom cookbooks skipped via --no-ucc switch.'.foreground(:blue)
          end

          # run setup on the remove instances
          #
          if command_options[:setup]
            hash = {}
            hash[:comment]  = 'running setup'
            hash[:stack_id] = @stack_id
            hash[:command]  = { name: 'setup' }
            begin
              if deployment_id.nil? || !command_options[:ucc]
                STDERR.puts "\nTriggering setup for remote stack (#{@stack_id})".foreground(:blue)
              else
                # Wait for deployment to finish successfully
                action = wait_for_deployment(opsworks, deployment_id)
              end
              if defined? action || action[:success]
                STDERR.puts "\n\tRecipes updated successfully".foreground(:green)
                STDERR.puts "\n\tTriggering setup for remote stack (#{@stack_id})".foreground(:blue)

                if command_options[:rolling]
                  STDERR.puts "\n\t\t using rolling deployment".foreground(:blue)
                  rolling_deployment(opsworks, hash)
                else
                  STDERR.puts "\n\t\t all at once".foreground(:red)
                  unless command_options[:auto]
                    STDERR.puts "\n\t\t Are you sure (y) or did you mean to do a rolling deployment (r)?".foreground(:red)
                    are_you_sure = STDIN.gets.chomp
                  end
                  if are_you_sure.nil? || are_you_sure == 'y'
                    STDERR.puts "\n\t\t Shrink tried to interfer, but failed. Running on all instances at once!".foreground(:green)
                    resp = opsworks.create_deployment(hash)
                    deployment_id = resp.deployment_id
                    result = wait_for_deployment(opsworks, deployment_id)
                    if !result[:success]
                      STDERR.puts "\t\tCould not run setup on instance #{hash[:instance_id]} ".foreground(:red)
                      STDERR.puts "\t\t\tSad details: " + result[:deployment].to_s
                      abort("")
                    end
                  elsif are_you_sure == 'r'
                    STDERR.puts "\n\t\t Shrink interfered. Using rolling deployment.".foreground(:green)
                    rolling_deployment(opsworks, hash)
                  else
                    STDERR.puts "\n\t\t Shrink interfered. Patient cured. Therapy ended.".foreground(:green)
                  end
                end
              else
                STDERR.puts "\tCould not run setup recipes".foreground(:red)
                abort("")
              end
            rescue Aws::OpsWorks::Errors::ServiceError => e
              STDERR.puts "\tCaught error while attempting to trigger deployment: ".foreground(:red)
              STDERR.puts "\t\t#{e}"
              abort("")
            else
              STDERR.puts 'Done!'.foreground(:green)
            end
          end
        end
      end
    end
  end
end
