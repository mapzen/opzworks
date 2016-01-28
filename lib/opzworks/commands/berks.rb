require 'aws-sdk'
require 'trollop'
require 'opzworks'
require 'rainbow/ext/string'

require_relative 'include/run_local'
require_relative 'include/populate_stack'
require_relative 'include/manage_berks_repos'

module OpzWorks
  class Commands
    class BERKS
      def self.banner
        'Build the stack berkshelf'
      end

      def self.run
        options = Trollop.options do
          banner <<-EOS.unindent
            #{BERKS.banner}

              opzworks berks stack1 stack2 ...

            The stack name can be passed as any unique regex. If there is
            more than one match, it will simply be skipped.

            Options:
          EOS
          opt :update, 'Trigger update_custom_cookbooks on stack after uploading a new cookbook tarball.', default: true
          opt :clone, 'Only clone the management repo, then exit.', short: 'c', default: false
        end
        ARGV.empty? ? Trollop.die('no stacks specified') : false

        config = OpzWorks.config

        aws_credentials_provider = Aws::SharedCredentials.new(profile_name: config.aws_profile)
        s3 = Aws::S3::Resource.new(region: config.aws_region, credentials: aws_credentials_provider)

        opsworks = Aws::OpsWorks::Client.new(region: config.aws_region, profile: config.aws_profile)
        response = opsworks.describe_stacks

        # loops over inputs
        ARGV.each do |opt|
          var = populate_stack(opt, response)
          next if var == false

          hash = {
            'PROJECT:'      => @project,
            'CHEF VERSION:' => @chef_version,
            'STACK ID:'     => @stack_id,
            'S3 PATH:'      => @s3_path,
            'S3 URL:'       => @s3_source_url,
            'BRANCH:'       => @branch
          }
          puts "\n"
          puts '-------------------------------'
          hash.each { |k, v| printf("%-25s %-25s\n", k.foreground(:green), v.foreground(:red)) }
          puts '-------------------------------'

          puts "\n"
          var = manage_berks_repos
          next if var == false
          next if options[:clone] == true

          berks_cook_path  = config.berks_base_path || '/tmp'
          cook_path        = "#{berks_cook_path}/#{@project}-#{@branch}"
          install_path     = cook_path + '/' + "cookbooks-#{@project}-#{@branch}"
          cookbook_tarball = config.berks_tarball_name || 'cookbooks.tgz'
          cookbook_upload  = cook_path + '/' "#{cookbook_tarball}"
          s3_bucket        = config.berks_s3_bucket || 'opzworks'
          overrides        = 'overrides'

          # berks
          #
          if !File.exist?("#{@target_path}/Berksfile.lock")
            puts "\nNo Berksfile.lock, running berks install before vendoring".foreground(:blue)
            run_local <<-BASH
              cd #{@target_path}
              berks install
              git add Berksfile.lock
            BASH
          end

          puts "\nUpdating the berkshelf".foreground(:blue)
          run_local <<-BASH
            cd #{@target_path}
            berks update
          BASH

          puts "\nVendoring the berkshelf".foreground(:blue)
          run_local <<-BASH
            cd #{@target_path}
            berks vendor #{install_path}
          BASH

          # if there's an overrides file, just pull it and stuff the contents into the
          #   upload repo; the line is assumed to be a git repo. This is done to override
          #   opsworks templates without destroying the upstream cookbook.
          #
          #   For example, to override the default nginx cookbook's nginx.conf, create a git
          #     repo with the directory structure nginx/templates/default and place your
          #     custom nginx.conf.erb in it.
          #
          if File.file?("#{@target_path}/#{overrides}")
            FileUtils.mkdir_p(install_path) unless File.directory?(install_path)
            File.open("#{@target_path}/#{overrides}") do |f|
              f.each_line do |line|
                puts "Copying override #{line}".foreground(:blue)
                `cd #{install_path} && git clone #{line}`
              end
            end
          end

          puts 'Committing changes and pushing'.foreground(:blue)
          system "cd #{@target_path} && git commit -am 'berks update'; git push origin #{@branch}"

          puts 'Creating tarball of cookbooks'.foreground(:blue)
          FileUtils.mkdir_p(cook_path)
          run_local "tar czf #{cookbook_upload} -C #{install_path} ."

          # upload
          #
          puts 'Uploading to S3'.foreground(:blue)

          begin
            obj = s3.bucket(s3_bucket).object("#{@s3_path}/#{cookbook_tarball}")
            obj.upload_file(cookbook_upload)
          rescue StandardError => e
            puts "Caught exception while uploading to S3 bucket #{s3_bucket}: #{e}".foreground(:red)
            puts 'Cleaning up before exiting'.foreground(:blue)
            FileUtils.rm(cookbook_upload)
            FileUtils.rm_rf(install_path)
            abort
          else
            puts "Completed successful upload of #{@s3_path}/#{cookbook_tarball} to #{s3_bucket}!".foreground(:green)
          end

          # cleanup
          #
          puts 'Cleaning up'.foreground(:blue)
          FileUtils.rm(cookbook_upload)
          FileUtils.rm_rf(install_path)
          puts 'Done!'.foreground(:green)

          # update remote cookbooks
          #
          if options[:update] == true
            puts "Triggering update_custom_cookbooks for remote stack (#{@stack_id})".foreground(:blue)

            hash = {}
            hash[:comment]  = 'shake and bake'
            hash[:stack_id] = @stack_id
            hash[:command]  = { name: 'update_custom_cookbooks' }

            begin
              opsworks.create_deployment(hash)
            rescue Aws::OpsWorks::Errors::ServiceError => e
              puts 'Caught error while attempting to trigger deployment: '.foreground(:red)
              puts e
            end
          else
            puts 'Update custom cookbooks skipped via --no-update switch.'.foreground(:blue)
          end
        end
      end
    end
  end
end
