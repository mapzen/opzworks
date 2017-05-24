def rolling_deployment opsworks, hash
  require 'byebug'

  opsworks.describe_instances({stack_id: hash[:stack_id]}).instances.each{ |instance|
    hash[:instance_ids] = [instance[:instance_id]]
    resp = opsworks.create_deployment(hash)
    deployment_id = resp.deployment_id
    result = wait_for_deployment(opsworks, deployment_id)
    if !result[:success]
      puts "Could not run setup on instance #{hash[:instance_id]} ".foreground(:red)
      puts "Sad details: " + result[:deployment].to_s
      break
    end
  }
end
