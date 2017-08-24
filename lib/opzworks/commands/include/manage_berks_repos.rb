# frozen_string_literal: true

def manage_berks_repos config
  @target_path = File.expand_path(config.berks_path, File.dirname(__FILE__))
  branch = config.chef_branch

  if config.is_local_branch
    puts "Changing to #{@target_path}"
    puts "Checking out branch: ".foreground(:blue) + branch.foreground(:green)
    run_local <<-BASH
      cd #{@target_path}
      git checkout #{branch}
    BASH
  else
    if !File.directory?(@target_path)
      protocol = 'git@'
      if !config.berks_repository_protocol.nil?
        case config.berks_repository_protocol
        when 'ssh'
          protocol = 'ssh://'
        when 'https'
          protocol = 'https://'
        else
          puts 'Repository protocol ' + config.berks_repository_protocol + ' not supported'.foreground(:red)
        end
      end

      if config.berks_repository_path.nil?
        puts 'Please specify the berks-repository-path'.foreground(:red)
      end

      if !config.berks_repository_user.nil?
        repo = protocol + config.berks_repository_user + '@' + config.berks_repository_path
      else
        repo = protocol + config.berks_repository_path
      end

      puts "#{@target_path} does not exist!".foreground(:red)
      puts "Attempting to create..."
      run_local <<-BASH
        mkdir #{@target_path}
      BASH

      puts 'Attempting git clone of '.foreground(:blue) + repo.foreground(:green)

      run_local <<-BASH
        cd #{config.berks_base_path}
        git clone #{repo}
        git checkout #{branch}
      BASH
    else
      puts "Changing to #{@target_path}"
      puts "Git pull from #{repo}, branch: ".foreground(:blue) + branch.foreground(:green)
      run_local <<-BASH
        cd #{@target_path}
        git checkout #{branch} && git pull origin #{branch}
      BASH
    end
  end
end
