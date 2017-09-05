def git_merge(path, from_branch, to_branch, merge_method, tag_version='', environment='', deployment_script = nil)
  puts "Checking out chef's from_branch #{from_branch} and pulling to be up to date".foreground(:blue)
  run_local <<-BASH
    cd #{path}
    git checkout #{from_branch} && git pull
  BASH

  puts "Checking out chef's to_branch #{to_branch} and pulling to be up to date".foreground(:blue)
  run_local <<-BASH
    cd #{path}
    git checkout #{to_branch} && git pull
  BASH

  puts "Merging the branches using git #{merge_method}".foreground(:blue)
  # Let's remove a git from merge_method includes a merge_method
  merge_method.gsub('git ', '') if merge_method.include?('git')
  run_local <<-BASH
    cd #{path}
    git checkout #{to_branch}
    git #{merge_method} #{from_branch}
  BASH

  unless deployment_script.nil? || !deployment_script
    puts "Running the deployment script deployment_script: #{deployment_script} #{environment} #{tag_version}".foreground(:blue)
    run_local <<-BASH
      cd #{path}
      #{deployment_script} #{environment} #{tag_version}
    BASH
  end

  puts "Pushing to #{to_branch} and tagging with #{tag_version}"
  run_local <<-BASH
    cd #{path}
    git checkout #{to_branch}
    git add .
    git commit -m "Commiting app version #{tag_version}"
    git fetch --tags
    git tag #{tag_version}
    git push origin #{to_branch} --tags --force
  BASH
end
