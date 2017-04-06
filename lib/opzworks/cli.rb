# frozen_string_literal: true

require 'trollop/subcommands'
require 'opzworks'

module OpzWorks
  class CLI
    def self.start
      Trollop::Subcommands::register_global do
        version "opzworks #{OpzWorks::VERSION} (c) #{OpzWorks::AUTHORS.join(', ')}"
        banner <<-EOS.unindent
          usage: opzworks [options] command [command options] stack1 stack2

          #{OpzWorks::SUMMARY}

          Options
            -e Environment, must correlate to the branch name in the repository where the berkshelf is located
            -r The region of your cloud provider you want to use (currently only AWS is supported)
            -p The path to the berkshelf

          Env
            The environment you want to use. Must correspond to the branch name of the berks repository.

          Supported Commands
            berks #{OpzWorks::Commands::BERKS.banner}

          Currently not supported
            ssh  #{OpzWorks::Commands::SSH.banner}
            cmd  #{OpzWorks::Commands::CMD.banner}
            json #{OpzWorks::Commands::STACKJSON.banner}
            elastic #{OpzWorks::Commands::ELASTIC.banner}

          For help with specific commands, run:
            opzworks COMMAND -h/--help

          Options:
        EOS
        opt :environment, 'Specify the environment for the stack, e.g. "staging". Required.', default: 'development', short: 'e', type: :string
        opt :region, 'Specify the AWS region where the stack can be found', short: 'r', type: :string
        opt :berks_path, 'Specify the path to the local berkshelf where the stack can be found', short: 'p', type: :string
      end

      Trollop::Subcommands::register_subcommand('berks') do
        banner <<-EOS.unindent

          #{OpzWorks::Commands::BERKS.banner}

            opzworks env berks stack1 stack2 ...

          The stack name can be passed as any unique regex. If there is
          more than one match, it will simply be skipped.

          Options:
        EOS
        opt :ucc, 'Trigger update_custom_cookbooks on stack after uploading a new cookbook tarball.', default: true
        opt :update, 'Run berks update before packaging the Berkshelf.', default: false, short: 'u'
        opt :cookbooks, 'Run berks update only for the specified cookbooks (requires -u)', type: :strings, default: nil, short: 'c'
        opt :clone, 'Only clone the management repo, then exit.', default: false
      end

      Trollop::Subcommands::register_subcommand('ssh') do
        banner <<-EOS.unindent
          #{OpzWorks::Commands::SSH.banner}

            opzworks ssh {stack1} {stack2} {...}

          The stack name can be passed as any unique regex. If no
          arguments are passed, the command will iterate over all stacks.

          Options:
        EOS
        opt :update, 'Update ~/.ssh/config directly'
        opt :backup, 'Backup old SSH config before updating'
        opt :quiet, 'Use SSH LogLevel quiet', default: true
        opt :private, 'Return private IPs, rather than the default of public', default: false
        opt :raw, 'Return only raw IPs rather than .ssh/config format output', default: false
      end

      Trollop::Subcommands::register_subcommand('json') do
        banner <<-EOS.unindent
          #{OpzWorks::Commands::STACKJSON.banner}

            opzworks json stack1 stack2 ...

          The stack name can be passed as any unique regex. If there is
          more than one match, it will simply be skipped.

          Options:
        EOS
        opt :quiet, 'Update the stack json without confirmation', short: 'q', default: false
        opt :context, 'Change the number lines of diff context to show', default: 5
        opt :clone, 'Just clone the management repo then exit', short: 'c', default: false
      end

      Trollop::Subcommands::register_subcommand('elastic') do
        banner <<-EOS.unindent
          #{OpzWorks::Commands::ELASTIC.banner}

            opzworks elastic stack1 stack2 ... [--start|--stop|--bounce|--rolling]

          The stack name can be passed as any unique regex. If there is
          more than one match, it will simply be skipped.

          Options:
        EOS
        opt :start, 'Start Elastic', default: false
        opt :stop, 'Stop Elastic', default: false
        opt :bounce, 'Bounce (stop/start) Elastic', default: false
        opt :rolling, 'Perform a rolling restart of Elastic', default: false
        opt :old_service_name, "Use 'elasticsearch' as the service name, otherwise use the layer shortname", default: false
      end

      Trollop::Subcommands::register_subcommand('cmd') do
        banner <<-EOS.unindent
          #{OpzWorks::Commands::CMD.banner}

            opzworks cmd [--list-stacks]

          Options:
        EOS
        opt :'list-stacks', 'List all our stacks', default: false
      end

      result = Trollop::Subcommands::parse!

      if !result.global_options[:environment_given]
        puts 'No environment specified, using development!'
        environment = 'development'
      else
        environment = result.global_options[:environment]
      end

      if !result.global_options[:region_given]
        config = OpzWorks.config environment, result.global_options[:berks_path]
        puts 'No region specified, using ' + config.aws_region + ' from system config.'
      else
        aws_region = result.global_options[:region]
        config = OpzWorks.config environment, result.global_options[:berks_path], aws_region
      end

      case result.subcommand
      when 'ssh'
        puts 'This version of the gem currently only supports the berks command'
        #OpzWorks::Commands::SSH.run
      when 'json'
        puts 'This version of the gem currently only supports the berks command'
        #OpzWorks::Commands::STACKJSON.run
      when 'berks'
        OpzWorks::Commands::BERKS.run config, result.subcommand_options
      when 'elastic'
        puts 'This version of the gem currently only supports the berks command'
        #OpzWorks::Commands::ELASTIC.run
      when 'cmd'
        puts 'This version of the gem currently only supports the berks command'
        #OpzWorks::Commands::CMD.run
      when nil
        puts 'no command specified'
      else
        puts "unknown command #{cmd_options[:command]}"
      end
    end
  end
end
