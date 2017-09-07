# frozen_string_literal: true

require 'aws-sdk'
require 'trollop'
require 'opzworks'
require 'rainbow/ext/string'
require 'byebug'

require_relative 'include/run_local'
require_relative 'include/populate_stack'
require_relative 'include/wait_for_deployment'
require_relative 'include/rolling_deployment'
require_relative 'include/git_merge'

module OpzWorks
  class Commands
    class DEPLOY
      def self.banner
        'Deploy on the stack'
      end

      def self.run config, command_options

        abort('No app path specified').foreground(:red) if config.app_path.empty?

        # loops over inputs
        ARGV.each do |stack|

          if config.aws_credentials_path
            aws_credentials_provider = Aws::Credentials.new(config.aws_access_key, config.aws_secret_access_key)
            opsworks = Aws::OpsWorks::Client.new(region: config.aws_region, credentials: aws_credentials_provider)
          else
            aws_credentials_provider = Aws::SharedCredentials.new(profile_name: config.aws_profile)
            opsworks = Aws::OpsWorks::Client.new(region: config.aws_region, profile: config.aws_profile)
          end

          response = opsworks.describe_stacks

          var = populate_stack(stack, response)
          next if var == false
          hash = {
            'CHEF VERSION:' => @chef_version,
            'STACK ID:'     => @stack_id
          }

          STDERR.puts "\n"
          STDERR.puts '-------------------------------'
          hash.each { |k, v| printf("%-25s %-25s\n", k.foreground(:green), v.foreground(:red)) }
          STDERR.puts '-------------------------------'

          # Since we wait for the end of the successful setup during opzwork berks, this will only be executed afterwards
          command_options[:tag_version] = `date +%F-%H-%M-%S`.gsub(/\n/,'') if !command_options[:tag_version]

          # This calls opzworks berks...
          if command_options[:from_branch_chef] && command_options[:to_branch_chef]
            # This pulls and merges the from_ & to_branches with merge_method, tags the version and pushes to to_branch
            git_merge(
              config.berks_path,
              command_options[:from_branch_chef],
              command_options[:to_branch_chef],
              command_options[:merge_method],
              command_options[:tag_version]
            )
            rolling = command_options[:rolling] ? '-r' : ''
            STDERR.puts 'Starting chef setup'.foreground(:blue)
            cmd = "opzworks berks -b #{command_options[:to_branch_chef]} -c -s #{rolling} -y 'true' #{stack}"
            Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
              stdin.close
              stderr.each_line { |line| STDERR.puts line }
              exit_status = wait_thr.value
              unless exit_status.success?
                abort "\n\nChef berks failed! Details can be found above. Aborting deployment.".foreground(:red)
              end
            end
          end

          if command_options[:to_branch] && command_options[:from_branch]

            # Now deploy the app itselfs
            STDERR.puts 'Starting app deployment'.foreground(:blue)
            # This pulls and merges the from_ & to_branches with merge_method, runs the deployment_script, tags the version and pushes to to_branch
            git_merge(
              config.app_path,
              command_options[:from_branch],
              command_options[:to_branch],
              command_options[:merge_method],
              command_options[:tag_version],
              command_options[:environment],
              command_options[:deployment_script]
            )

            abort("Please specify an app id for environment #{command_options[:environment]} on stack #{stack}".foreground(:red)) unless config.aws_app_id

            hash = {}
            hash[:comment]  = 'deploying the app'
            hash[:stack_id] = @stack_id
            hash[:app_id] = config.aws_app_id
            hash[:command]  = {
              name: 'deploy'
            }

            if command_options[:rolling]
              STDERR.puts "\n\t using rolling deployment".foreground(:blue)
              rolling_deployment(opsworks, hash)
            else
              STDERR.puts "\n\t all at once".foreground(:red)
              unless command_options[:auto]
                STDERR.puts "\n\t\t Are you sure (y) or did you mean to do a rolling deployment (r)?".foreground(:red)
                are_you_sure = STDIN.gets.chomp
              end

              if are_you_sure.nil? || are_you_sure == 'y'
                STDERR.puts "\n\t Shrink tried to interfer, but failed. Running on all instances at once!".foreground(:green)
                resp = opsworks.create_deployment(hash)
                deployment_id = resp.deployment_id
                result = wait_for_deployment(opsworks, deployment_id)
                if !result[:success]
                  STDERR.puts "\tCould not deploy app! ".foreground(:red)
                  break
                end
              elsif are_you_sure == 'r'
                STDERR.puts "\n\t Shrink interfered. Using rolling deployment.".foreground(:green)
                rolling_deployment(opsworks, hash)
              else
                STDERR.puts "\n\t Shrink interfered. Patient cured. Therapy ended.".foreground(:green)
              end
            end
          end
        end
      end
    end
  end
end
