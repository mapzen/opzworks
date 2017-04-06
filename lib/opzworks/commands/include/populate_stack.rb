# frozen_string_literal: true

def populate_stack(current_stack, aws_response = {})
  # loops over inputs
  stack = {}
  count = 0

  aws_response[:stacks].each do |st|
    next unless st[:name].chomp =~ /#{current_stack}/
    count = count += 1
    stack = st.to_hash
  end

  # break?
  if count < 1
    puts 'No matching stacks found for input '.foreground(:yellow) + input.foreground(:green) + ', skipping.'.foreground(:yellow)
    return false
  elsif count > 1
    puts 'Found more than one stack matching input '.foreground(:yellow) + input.foreground(:green) + ', skipping.'.foreground(:yellow)
    return false
  else
    @stack_json     = stack[:custom_json] || ''
    @s3_path        = stack[:name]
    @stack_id       = stack[:stack_id]
    @arn            = stack[:arn]
    @region         = stack[:region]
    @default_subnet = stack[:default_subnet_id]
    @default_os     = stack[:default_os]
    @chef_version   = stack[:configuration_manager][:version]
    @s3_source_url  = stack[:custom_cookbooks_source][:url] || ''
  end
end
