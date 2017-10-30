def wait_for_deployment opsworks, id, max_minutes = 30

  minutes_passed = 0
  poison = false

  loop do
    break if poison
    deployment = check_deployment(opsworks,id)
    STDERR.puts "\t\tCurrent status for deployment #{id}: " + deployment.status.foreground(:yellow)
    if deployment.status == "successful"
      poison = true
      return {success: true, deployment: deployment}
    elsif deployment.status == "failed"
      poison = true
      return {success: false, deployment: deployment}
    end
    if minutes_passed == max_minutes
      poison = true
      return {success: false, deployment: deployment}
    end
    minutes_passed += 1
    sleep(30)
    redo
  end

end

def check_deployment opsworks, id
  resp = opsworks.describe_deployments({
    deployment_ids: [id]
  })
  if resp.deployments
    resp.deployments.first
  end
end
