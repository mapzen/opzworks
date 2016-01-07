def populate_stack(input, data = {})
  # loops over inputs
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
    @stack_json = match[:custom_json]
    @project    = match[:name].split('::').first
    @s3_path    = match[:name].gsub('::', '-')
    @stack_id   = match[:stack_id]
    @branch     = (match[:name].split('::')[1] + '-' + match[:name].split('::')[2]).gsub('::', '-')

    hash = {
      'PROJECT:'  => @project,
      'STACK ID:' => @stack_id,
      'S3 PATH:'  => @s3_path,
      'BRANCH:'   => @branch
    }
    puts "\n"
    hash.each { |k, v| printf("%-25s %-25s\n", k.foreground(:green), v.foreground(:red)) }
  end
end
