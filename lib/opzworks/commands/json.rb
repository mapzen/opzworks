# frozen_string_literal: true

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
    class STACKJSON
      def self.banner
        'Update stack json'
      end

      def self.run
        options = Trollop.options do
          banner <<-EOS.unindent
            #{STACKJSON.banner}

              opzworks json stack1 stack2 ...

            The stack name can be passed as any unique regex. If there is
            more than one match, it will simply be skipped.

            Options:
          EOS
          opt :quiet, 'Update the stack json without confirmation', short: 'q', default: false
          opt :context, 'Change the number lines of diff context to show', default: 5
          opt :clone, 'Just clone the management repo then exit', short: 'c', default: false
        end
        ARGV.empty? ? Trollop.die('no stacks specified') : false

        config   = OpzWorks.config
        client   = Aws::OpsWorks::Client.new(region: config.aws_region, profile: config.aws_profile)
        response = client.describe_stacks

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

          json = File.read("#{@target_path}/stack.json")
          print "\nValidating json before continuing... ".foreground(:blue)
          begin
            JSON.load(json)
            print 'PASSED!'.foreground(:green)
          rescue JSON::ParserError => e
            print 'FAILED!'.foreground(:red)
            puts "\n" + e.to_s.lines.first
            abort
          end

          diff = Diffy::Diff.new(@stack_json + "\n", json, context: options[:context])
          diff_str = diff.to_s(:color).chomp

          hash = {}
          hash[:stack_id] = @stack_id
          hash[:custom_json] = json

          if diff_str.empty?
            puts "\nThere are no differences between the existing stack json and the json you\'re asking to push.".foreground(:yellow)
          elsif options[:quiet]
            puts 'Quiet mode detected. Pushing the following updated json:'.foreground(:yellow)
            puts diff_str

            puts "\nCommitting changes and pushing".foreground(:blue)
            system "cd #{@target_path} && git commit -am 'stack update'; git push origin #{@branch}"

            client.update_stack(hash)
            puts "\nStack json updated!".color(:green)
          else
            puts "\nThe following is a partial diff of the existing stack json and the json you're asking to push:".foreground(:yellow)
            puts diff_str
            STDOUT.print "\nType ".foreground(:yellow) + 'yes '.foreground(:blue) + 'to continue, any other key will abort: '.foreground(:yellow)
            input = STDIN.gets.chomp
            if input =~ /^y/i
              puts "\nCommitting changes and pushing".foreground(:blue)
              system "cd #{@target_path} && git commit -am 'stack update'; git push origin #{@branch}"

              client.update_stack(hash)
              puts "\nStack json updated!".color(:green)
            else
              puts 'Update skipped.'.foreground(:red)
            end
          end
        end
      end
    end
  end
end
