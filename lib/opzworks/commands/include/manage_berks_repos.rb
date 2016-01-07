def manage_berks_repos
  config = OpzWorks.config
  @target_path = File.expand_path(config.berks_repository_path + "/opsworks-#{@project}", File.dirname(__FILE__))

  if !File.directory?(@target_path)
    if config.berks_github_org.nil?
      puts "#{@target_path} does not exist, and 'berks-github-org' is not set in ~/.aws/config, skipping.".foreground(:yellow)
      @berks_repo_failure = true
    else
      puts "#{@target_path} does not exist!".foreground(:red)
      puts 'Attempting git clone of '.foreground(:blue) + "git@github.com:#{config.berks_github_org}/opsworks-#{@project}.".foreground(:green)
      run_local <<-BASH
        cd #{config.berks_repository_path}
        git clone git@github.com:#{config.berks_github_org}/opsworks-#{@project}.git
      BASH
    end
  else
    puts "Git pull from #{@target_path}, branch: ".foreground(:blue) + @branch.foreground(:green)
    run_local <<-BASH
      cd #{@target_path}
      git checkout #{@branch} && git pull origin #{@branch}
    BASH
  end
end
