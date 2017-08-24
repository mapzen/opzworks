def rolling_deployment opsworks, hash
  require 'byebug'

  opsworks.describe_instances({stack_id: hash[:stack_id]}).instances.each{ |instance|
    STDERR.puts "\n\tRunning #{hash[:command][:name]} on #{instance[:hostname]}".foreground(:blue)
    hash[:instance_ids] = [instance[:instance_id]]
    begin
      resp = opsworks.create_deployment(hash)
    rescue Exception => e
      STDERR.puts "\t\tCould not create deployment, likely because the instance was not running. Please check Amazon's exception below for details!".foreground(:red)
      STDERR.puts "\t\t\t#{e.message}".foreground(:red)
      next
    end
    deployment_id = resp.deployment_id
    result = wait_for_deployment(opsworks, deployment_id)
    if !result[:success]
      STDERR.puts "\t\tCould not run #{hash[:command][:name]} on instance #{hash[:instance_id]} ".foreground(:red)
      abort("")
    end
  }
end
