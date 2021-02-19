# frozen_string_literal: true

require 'aws-sdk-opsworks'
require 'trollop'
require 'opzworks'

SSH_PREFIX  = '# --- OpzWorks ---'
SSH_POSTFIX = '# --- End of OpzWorks ---'

module OpzWorks
  class Commands
    class SSH
      def self.banner
        'Generate and update SSH configuration files'
      end

      def self.run options
        config = OpzWorks.config
        client = Aws::OpsWorks::Client.new(region: config.aws_region, profile: config.aws_profile)

        stacks     = []
        stack_data = client.describe_stacks

        if ARGV.empty?
          stack_data[:stacks].each { |stack| stacks.push(stack) }
        else
          ARGV.each do |arg|
            stack_data[:stacks].each do |stack|
              stacks.push(stack) if stack[:name] =~ /#{arg}/
            end
          end
        end

        stacks.each do |stack|
          instances   = []
          stack_name  = ''

          stack_name = stack[:name].gsub('::', '-')

          result = client.describe_instances(stack_id: stack[:stack_id])
          instances += result.instances.select { |i| i[:status] != 'stopped' }

          instances.map! do |instance|
            ip = if options[:private]
                   instance[:private_ip]
                 else
                   instance[:elastic_ip].nil? ? instance[:public_ip] : instance[:elastic_ip]
                 end

            if options[:raw]
              puts ip
            else
              next if ip.nil?
              parameters = {
                'Host'     => "#{instance[:hostname]}-#{stack_name}",
                'HostName' => ip,
                'User'     => config.ssh_user_name
              }
              parameters['LogLevel'] = 'quiet' if options[:quiet]
              parameters.map { |param| param.join(' ') }.join("\n  ")
            end
          end

          next if options[:raw]
          new_contents = "#{instances.join("\n")}\n"

          if options[:update]
            ssh_config = "#{ENV['HOME']}/.ssh/config"
            old_contents = File.read(ssh_config)

            if options[:backup]
              backup_name = ssh_config + '.backup'
              File.open(backup_name, 'w') { |file| file.puts old_contents }
            end

            File.open(ssh_config, 'w') do |file|
              file.puts old_contents.gsub(
                /\n?\n?#{SSH_PREFIX}.*#{SSH_POSTFIX}\n?\n?/m,
                ''
              )
              file.puts new_contents
            end

            puts "Successfully updated #{ssh_config} with #{instances.length} instances!"
          else
            puts new_contents.strip
          end
        end
      end
    end
  end
end
