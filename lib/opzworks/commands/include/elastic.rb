def opsworks_list_ips(options = {})
  response = @client.describe_instances options
  @ip_addrs = []
  response[:instances].each { |instance| @ip_addrs << instance.private_ip if instance[:status] == 'online' }
rescue StandardError => e
  abort "Exception raised: #{e}".foreground(:red)
end

def es_get_input(input, data = {}, *cmd)
  match = {}
  count = 0

  data[:stacks].each do |stack|
    next unless stack[:name].chomp =~ /#{input}/
    count = count += 1
    match = stack.to_hash
  end

  # break?
  if count < 1
    puts 'No matching stacks found for input '.foreground(:yellow) + input.foreground(:green) + ', skipping.'.foreground(:yellow)
    return false
  elsif count > 1
    puts 'Found more than one stack matching input '.foreground(:yellow) + input.foreground(:green) + ', skipping.'.foreground(:yellow)
    return false
  else
    puts 'Operating on stack '.foreground(:blue) + match[:name].to_s.foreground(:green)
    layers = @client.describe_layers(stack_id: match[:stack_id])
    layers[:layers].each { |layer| printf("%-30s %-50s\n", layer[:name], layer[:layer_id]) }

    STDOUT.print 'Specify a layer: '.foreground(:blue)
    layer = STDIN.gets.chomp

    unless cmd.include? 'start'
      STDOUT.print 'Disable shard allocation before starting? (true/false, default is true): '.foreground(:blue)
      disable_allocation = STDIN.gets.chomp
      @disable_shard_allocation = case disable_allocation
                                  when false
                                    false
                                  else
                                    true
                                  end
    end

    options = {}
    if layer == ''
      puts 'Must specify a layer.'.foreground(:red)
      return false
    else
      options[:layer_id] = layer
      get_shortname = @client.describe_layers(layer_ids: [layer])
      get_shortname[:layers].each { |l| @service_name = l[:shortname] }
    end
    opsworks_list_ips(options)
  end
end

def es_enable_allocation(ip, type)
  puts "Cluster routing.allocation is being set to #{type}".foreground(:blue)
  conn = Faraday.new(url: "http://#{ip}:9200") do |f|
    f.adapter :net_http
  end

  count = 0
  loop do
    begin
      conn.put do |req|
        req.url '/_cluster/settings'
        req.body = "{\"transient\": {\"cluster.routing.allocation.enable\": \"#{type}\"}}"
        req.options[:timeout]       = 5
        req.options[:open_timeout]  = 2
      end
      break
    rescue StandardError => e
      puts 'Caught exception while trying to change allocation state: '.foreground(:yellow) + e.foreground(:red) + ', looping around...'.foreground(:yellow) if count == 0
      count += 1
      sleep 1
    end
  end
end

def es_service(command, ips = [], service_name = 'elasticsearch')
  puts "Operating on ES with command #{command}".foreground(:yellow)
  user = ENV['USER']

  Net::SSH::Multi.start do |session|
    ips.each do |ip|
      session.use "#{user}@#{ip}"
    end

    Timeout.timeout(10) do
      session.exec "sudo service #{service_name} #{command}"
    end
    session.loop
  end
end

def es_wait_for_status(ip, color)
  puts 'Waiting for cluster to go '.foreground(:blue) + color.foreground(:"#{color}")
  conn = Faraday.new(url: "http://#{ip}:9200") do |f|
    f.adapter :net_http
  end

  count = 0
  rescue_count = 0
  loop do
    begin
      response = conn.get do |req|
        req.url '/_cluster/health'
        req.options[:timeout]       = 5
        req.options[:open_timeout]  = 2
      end
      json = JSON.parse response.body
    rescue StandardError => e
      puts 'Caught exception while trying to check cluster status: '.foreground(:yellow) + e.foreground(:red) + ', looping around...'.foreground(:yellow) if rescue_count == 0
      rescue_count += 1
      printf '.'
      sleep 1
    else
      case json['status']
      when color
        puts "\nCluster is now ".foreground(:blue) + color.foreground(:"#{color}")
        break
      when 'green'
        puts "\nCluster is green, proceeding without waiting for requested status of #{color}".foreground(:green)
        break
      else
        count += 1
        if count == 10
          puts "\nStill waiting, cluster is currently ".foreground(:blue) + json['status'].to_s.foreground(:"#{json['status']}")
          count = 0
        end
        printf '.'
        sleep 1
      end
    end
  end
end
