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

        if ARGV.empty?
          puts 'no stacks specified'
          return
        end

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
            'BRANCH:'       => config.branch
          }

          puts "\n"
          puts '-------------------------------'
          hash.each { |k, v| printf("%-25s %-25s\n", k.foreground(:green), v.foreground(:red)) }
          puts '-------------------------------'

          puts "\n"
          var = manage_berks_repos(config)
          next if var == false
          next if command_options[:clone] == true

          time             = Time.new.utc.strftime('%FT%TZ')
          berks_cook_path  = config.berks_path || '/tmp'
          cook_path        = "#{berks_cook_path}/tmp-#{config.branch}"
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
            puts "\nNo Berksfile.lock, running berks install before packaging".foreground(:blue)
            run_local <<-BASH
              cd #{@target_path}
              berks install
              git add Berksfile.lock
            BASH
          end

          if command_options[:update] == true
            if command_options[:cookbooks].nil?
              puts "\nUpdating the berkshelf".foreground(:blue)
              run_local <<-BASH
                cd #{@target_path}
                berks update
              BASH
            else
              puts "\nUpdating the berkshelf for cookbook(s): ".foreground(:blue) + command_options[:cookbooks].join(', ').to_s.foreground(:green)
              run_local <<-BASH
                cd #{@target_path}
                berks update #{command_options[:cookbooks].join(' ')}
              BASH
            end
          else
            puts "\nNot running berks update".foreground(:blue)
          end

          puts "\nPackaging the berkshelf".foreground(:blue)
          run_local <<-BASH
            cd #{@target_path}
            berks package #{cook_path}/#{cookbook_tarball}
          BASH

          # backup previous if it exists
          #
          puts "\nBackup".foreground(:blue)
          begin
            s3_client.head_object(
              bucket: s3_bucket,
              key: "#{@s3_path}/#{cookbook_tarball}"
            )
          rescue Aws::S3::Errors::ServiceError
            puts "No existing #{cookbook_tarball} in #{s3_bucket}/#{@s3_path} to backup, continuing...".foreground(:yellow)
          else
            puts "Backing up existing #{cookbook_tarball} to #{@s3_path}/#{cookbook_tarball}-#{time}".foreground(:green)
            begin
              s3_client.copy_object(
                key: "#{@s3_path}/#{cookbook_tarball}-#{time}",
                bucket: s3_bucket,
                copy_source: "#{s3_bucket}/#{@s3_path}/#{cookbook_tarball}"
              )
            rescue Aws::S3::Errors::ServiceError => e
              puts "Caught exception trying to backup existing #{cookbook_tarball} in #{s3_bucket}:".foreground(:red)
              puts "\t#{e}"
              abort
            end
          end

          begin
            cull = s3_client.list_objects(
              bucket: s3_bucket,
              prefix: "#{@s3_path}/#{cookbook_tarball}-"
            )
          rescue Aws::S3::Errors::ServiceError => e
            puts "Caught exception trying to list backups in #{s3_bucket}:".foreground(:red)
            puts "\t#{e}"
          else
            backup_arr = []
            cull.contents.each { |k| backup_arr << k.key }
            backup_arr.pop(5) # keep last 5 backups

            unless backup_arr.empty?
              delete_arr = []
              until backup_arr.empty?
                puts "Adding backup #{backup_arr[0]} to the cull list".foreground(:green)
                delete_arr << backup_arr.pop

                arr_of_hash = []
                delete_arr.each { |i| arr_of_hash << { 'key': i } }

                puts 'Culling old backups'.foreground(:green)
                begin
                  s3_client.delete_objects(
                    bucket: s3_bucket,
                    delete: { objects: arr_of_hash }
                  )
                rescue Aws::S3::Errors::ServiceError => e
                  puts "Caught exception trying to delete backups in #{s3_bucket}:".foreground(:red)
                  puts "\t#{e}"
                end
              end
            end
          end

          # upload
          puts "\nUploading to S3".foreground(:blue)
          begin
            obj = s3.bucket(s3_bucket).object("#{@s3_path}/#{cookbook_tarball}")
            obj.upload_file(cookbook_upload)
          rescue Aws::S3::Errors::ServiceError => e
            puts "Caught exception while uploading to S3 bucket #{s3_bucket}:".foreground(:red)
            puts "\t#{e}"
            puts "\nCleaning up before exiting".foreground(:blue)

            FileUtils.rm_rf(cook_path)
            abort
          else
            puts "Completed successful upload of #{@s3_path}/#{cookbook_tarball} to #{s3_bucket}!".foreground(:green)
          end

          # cleanup
          #
          puts "\nCleaning up".foreground(:blue)
          FileUtils.rm_rf(cook_path)
          puts 'Done!'.foreground(:green)

          # update remote cookbooks
          #
          if command_options[:ucc] == true
            puts "\nTriggering update_custom_cookbooks for remote stack (#{@stack_id})".foreground(:blue)

            hash = {}
            hash[:comment]  = 'shake and bake'
            hash[:stack_id] = @stack_id
            hash[:command]  = { name: 'update_custom_cookbooks' }

            begin
              resp = opsworks.create_deployment(hash)
              deployment_id = resp.deployment_id
            rescue Aws::OpsWorks::Errors::ServiceError => e
              puts 'Caught error while attempting to trigger deployment: '.foreground(:red)
              puts "\t#{e}"
            else
              puts 'Done!'.foreground(:green)
              puts "\n"
            end
          else
            # puts 'Update custom cookbooks skipped via --no-ucc switch.'.foreground(:blue)
          end

          # update remote cookbooks
          #
          if command_options[:setup] == true
            hash = {}
            hash[:comment]  = 'shake and bake and now cut the cake'
            hash[:stack_id] = @stack_id
            hash[:command]  = { name: 'setup' }
            begin
              if deployment_id.nil? || !command_options[:ucc]
                puts "\nTriggering setup for remote stack (#{@stack_id})".foreground(:blue)
              else
                # Wait for deployment to finish successfully
                action = wait_for_deployment(opsworks, deployment_id)
              end
              if defined? action || action[:success]
                puts "\nRecipes updated successfully".foreground(:green)
                puts "\nTriggering setup for remote stack (#{@stack_id})".foreground(:blue)

                if command_options[:rolling] == true
                  puts "\n using rolling deployment".foreground(:blue)
                  rolling_deployment(opsworks, hash)
                else
                  puts "\n all at once".foreground(:red)
                  puts "\n Are you sure (y) or did you mean to do a rollind deployment (r)?".foreground(:red)
                  are_you_sure = STDIN.gets.chomp
                  if are_you_sure == 'y'
                    puts "\n Shrink tried to interfer. Patient died.".foreground(:green)
                    opsworks.create_deployment(hash)
                  elsif are_you_sure == 'r'
                    puts "\n Shrink interfered. Patient cured.".foreground(:green)
                    rolling_deployment(opsworks, hash)
                  else
                    puts "\n Shrink interfered. Patient cured. Therapy ended.".foreground(:green)
                  end
                end
              else
                puts "Could not run setup recipes".foreground(:red)
                puts "Sad details: " + action[:deployment].to_s
              end
            rescue Aws::OpsWorks::Errors::ServiceError => e
              puts 'Caught error while attempting to trigger deployment: '.foreground(:red)
              puts "\t#{e}"
            else
              puts 'Done!'.foreground(:green)
            end
          else
            # puts 'Update custom cookbooks skipped via --no-ucc switch.'.foreground(:blue)
          end
        end
      end
    end
  end
end
