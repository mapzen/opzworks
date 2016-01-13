require 'aws-sdk'
require 'trollop'
require 'diffy'
require 'opzworks'
require 'rainbow/ext/string'

require_relative 'include/run_local'
require_relative 'include/populate_stack'
require_relative 'include/manage_berks_repos'

module OpzWorks
  class Commands
    class JSON
      def self.banner
        'Update stack json'
      end

      def self.run
        options = Trollop.options do
          banner <<-EOS.unindent
            #{JSON.banner}

              opzworks json stack1 stack2 ...

            The stack name can be passed as any unique regex. If there is
            more than one match, it will simply be skipped.

            Options:
          EOS
          opt :quiet, 'Update the stack json without confirmation', short: 'q', default: false
          opt :context, 'Change the number lines of diff context to show', short: 'c', default: 5
        end
        ARGV.empty? ? Trollop.die('no stacks specified') : false

        config   = OpzWorks.config
        client   = Aws::OpsWorks::Client.new(region: config.aws_region, profile: config.aws_profile)
        response = client.describe_stacks

        ARGV.each do |opt|
          var = populate_stack(opt, response)
          next if var == false

          var = manage_berks_repos
          next if var == false

          json = File.read("#{@target_path}/stack.json")
          diff = Diffy::Diff.new(@stack_json + "\n", json, context: options[:context])
          diff_str = diff.to_s(:color).chomp

          hash = {}
          hash[:stack_id] = @stack_id
          hash[:custom_json] = json

          if diff_str.empty?
            puts 'There are no differences between the existing stack json and the json you\'re asking to push.'.foreground(:yellow)
          else
            if options[:quiet]
              puts 'Quiet mode detected. Pushing the following updated json:'.foreground(:yellow)
              puts diff_str

              puts 'Committing changes and pushing'.foreground(:blue)
              system "cd #{@target_path} && git commit -am 'stack update'; git push origin #{@branch}"

              client.update_stack(hash)
              puts 'Done!'.color(:green)
            else
              puts "The following is a partial diff of the existing stack json and the json you're asking to push:".foreground(:yellow)
              puts diff_str
              STDOUT.print "\nType ".foreground(:yellow) + 'yes '.foreground(:blue) + 'to continue, any other key will abort: '.foreground(:yellow)
              input = STDIN.gets.chomp
              if input =~ /^y/i
                puts 'Committing changes and pushing'.foreground(:blue)
                system "cd #{@target_path} && git commit -am 'stack update'; git push origin #{@branch}"

                client.update_stack(hash)
                puts 'Done!'.color(:green)
              else
                puts 'Update skipped.'.foreground(:red)
              end
            end
          end
        end
      end
    end
  end
end
