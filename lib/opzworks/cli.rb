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
            -r The region of your cloud provider you want to use (currently only AWS is supported)

          stack
            The stacks you want to use. Must correspond to the branch name of the berks repository.

          Supported Commands
            berks #{OpzWorks::Commands::BERKS.banner}
            deploy #{OpzWorks::Commands::DEPLOY.banner}

          Currently not supported
            ssh  #{OpzWorks::Commands::SSH.banner}
            cmd  #{OpzWorks::Commands::CMD.banner}
            json #{OpzWorks::Commands::STACKJSON.banner}
            elastic #{OpzWorks::Commands::ELASTIC.banner}

          For help with specific commands, run:
            opzworks COMMAND -h/--help

          Options:
        EOS
        opt :region, 'Specify the AWS region where the stack can be found', short: 'r', type: :string
      end

      Trollop::Subcommands::register_subcommand('berks') do
        banner <<-EOS.unindent

          #{OpzWorks::Commands::BERKS.banner}

            opzworks env berks stack1 stack2 ...

          The stack name can be passed as any unique regex. If there is
          more than one match, it will simply be skipped.

          Options:
        EOS
        opt :remote_branch, 'remote branch of the chef repository', short: 'b', type: :string
        opt :local_branch, 'local branch of the chef repository. Can be used in combination with gerrit reviews', short: 'l', type: :string
        opt :berks_path, 'Specify the path to the local berkshelf where the stack can be found', short: 'p', type: :string
        opt :ucc, 'Trigger update_custom_cookbooks on stack after uploading a new cookbook tarball.', default: false, short: 'c'
        opt :setup, 'Trigger setup on stack after uploading a new cookbook tarball.', default: false, short: 's'
        opt :rolling, 'Each action will be executed in a rolling manner, meaning instance after instance', default: false, short: 'r'
        opt :update, 'Run berks update before packaging the Berkshelf.', default: false, short: 'u'
        opt :cookbooks, 'Run berks update only for the named cookbooks (requires -u)', type: :strings, default: nil, short: 'n'
        opt :clone, 'Only clone the management repo, then exit.', default: false
        opt :auto, 'NOT RECOMMENDED! This will deactivate all questions, leaving you without chance to abort', short: 'y', default: 'false'
      end

      Trollop::Subcommands::register_subcommand('deploy') do
        banner <<-EOS.unindent
          #{OpzWorks::Commands::DEPLOY.banner}

            opzworks deploy {stack1} {stack2} {...}

          The stack name can be passed as any unique regex. If no
          arguments are passed, the command will iterate over all stacks.

          Options:
        EOS
        opt :from_branch, 'Branch from which to get the app code ( has to exist as local branch )', short: 'f', default: 'master', type: :string
        opt :to_branch, 'Branch to which to merge the from_branch ( has to exist as local branch, "merge --no-ff" will be used per default )', short: 't', default: 'staging', type: :string
        opt :merge_method, 'Git strategy to use to merge to from_ and to_branch', short: 'm', default: 'merge --no-ff', type: :string
        opt :deployment_script, "Relative path from app-path to script to use for deployment. Assumes it takes a git tag for the app's code as its only argument (see tag_version)", short: 'd', type: :string
        opt :environment, 'Environment in which to run the deployment script', short: 'e', default: 'staging', type: :string
        opt :tag_version, 'Version used as tag in git, defaults to date +%F-%H-%M-%S (i.e. 2017-08-29-18-48-06)', short: 'v', type: :string
        opt :from_branch_chef, 'Chef branch from which to deploy', short: 'b', default: 'master', type: :string
        opt :to_branch_chef, 'Chef branch to which to deploy', short: 'l', default: 'staging', type: :string
        opt :berks_path, 'Specify the path to the local berkshelf where the stack can be found', short: 'p', type: :string
        opt :setup_chef, 'Run chef setup after deployment', short: 's', default: false
        opt :rolling_chef, 'Setup chef in a rolling manor (-s needed)', short: 'r', default: false
        opt :auto, 'NOT RECOMMENDED! This will deactivate all questions, leaving you without chance to abort', short: 'y', default: 'false'
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

      abort('Please specify the stack you want to adress'.foreground(:red)) if ARGV.empty?

      if result.subcommand == 'berks'
        if !result.subcommand_options[:remote_branch_given] && !result.subcommand_options[:local_branch_given]
          abort("You need to specify a branch (remote (-b) or local (-l))")
        end

        pre_config = {}
        chef = {}

        is_local_branch = false

        if result.subcommand_options[:remote_branch_given]
          chef_branch = result.subcommand_options[:remote_branch]
          STDERR.puts 'Using remote branch ' + chef_branch
        else
          chef_branch = result.subcommand_options[:local_branch]
          is_local_branch = true
          STDERR.puts 'Using local branch ' + chef_branch
        end

        chef[:berks_path] = result.subcommand_options[:berks_path] if result.subcommand_options[:berks_path]
        chef[:is_local_branch] = is_local_branch
        chef[:chef_branch] = chef_branch

        pre_config[:chef] = chef

        if !result.global_options[:region_given]
          config = OpzWorks.config pre_config
          STDERR.puts 'No region specified, using ' + config.aws_region + ' from system config.'
        else
          aws_region = result.global_options[:region]
          config = OpzWorks.config pre_config, aws_region
        end
      end

      if result.subcommand == 'deploy'
        pre_config = {}
        app = {}
        pre_config[:app] = app

        if result.subcommand_options[:setup_chef]
          chef = {}
          if !result.subcommand_options[:from_branch_chef] && !result.subcommand_options[:to_branch_chef]
            abort("You need to specify a branch from which to deploy and / or a branch to which to deploy")
          end

          chef[:berks_path] = result.subcommand_options[:berks_path] if result.subcommand_options[:berks_path]
          chef[:to_branch_chef] = result.subcommand_options[:to_branch_chef] if result.subcommand_options[:to_branch_chef]
          chef[:from_branch_chef] = result.subcommand_options[:from_branch_chef] if result.subcommand_options[:from_branch_chef]
          chef[:setup] = result.subcommand_options[:setup] if result.subcommand_options[:setup]
          chef[:rolling] = result.subcommand_options[:rolling] if result.subcommand_options[:rolling]
          chef[:auto] = result.subcommand_options[:auto] if result.subcommand_options[:auto]
        end

        if !result.global_options[:region_given]
          config = OpzWorks.config pre_config
          STDERR.puts 'No region specified, using ' + config.aws_region + ' from system config.'
        else
          aws_region = result.global_options[:region]
          config = OpzWorks.config pre_config, aws_region
        end
      end

      unless result.subcommand_options[:auto] == "true"
        STDERR.puts "\nAre you sure you want to proceed on stack(s) '#{ARGV.join(',')}'? (y/n)".foreground(:red)
        abort('Exiting before something bad happened!'.foreground(:green)) if STDIN.gets.chomp == 'n'
        if result.subcommand_options[:setup_chef]
          STDERR.puts "\nAre you sure you want to merge chef branch '#{result.subcommand_options[:from_branch_chef]}' into chef branch '#{result.subcommand_options[:to_branch_chef]}'? (y/n)".foreground(:red)
          abort('Exiting before something bad happened!'.foreground(:green)) if STDIN.gets.chomp == 'n'
        end
        STDERR.puts "\nAre you sure you want to merge the app's '#{result.subcommand_options[:from_branch_chef]}' branch into the app's '#{result.subcommand_options[:to_branch_chef]}' branch? (y/n)".foreground(:red)
        abort('Exiting before something bad happened!'.foreground(:green)) if STDIN.gets.chomp == 'n'
        if result.subcommand_options[:deployment_script]
          STDERR.puts "\nAre you sure you want to execute the deployment script '#{result.subcommand_options[:deployment_script]}'? (y/n)".foreground(:red)
          abort('Exiting before something bad happened!'.foreground(:green)) if STDIN.gets.chomp == 'n'
        end
      end

      case result.subcommand
      when 'ssh'
        STDERR.puts 'This version of the gem currently only supports the berks command'
        #OpzWorks::Commands::SSH.run
      when 'json'
        STDERR.puts 'This version of the gem currently only supports the berks command'
        #OpzWorks::Commands::STACKJSON.run
      when 'berks'
        OpzWorks::Commands::BERKS.run config, result.subcommand_options
      when 'deploy'
        OpzWorks::Commands::DEPLOY.run config, result.subcommand_options
      when 'elastic'
        STDERR.puts 'This version of the gem currently only supports the berks command'
        #OpzWorks::Commands::ELASTIC.run
      when 'cmd'
        STDERR.puts 'This version of the gem currently only supports the berks command'
        #OpzWorks::Commands::CMD.run
      when nil
        STDERR.puts 'no command specified'
      else
        STDERR.puts "unknown command '#{result.subcommand}'".foreground(:red)
      end
    end
  end
end
