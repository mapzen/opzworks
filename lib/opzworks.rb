require 'opzworks/meta'
require 'opzworks/config'

# require our commands
%w(ssh json berks elastic).each do |cmd|
  require "opzworks/commands/#{cmd}"
end

class String
  def unindent
    gsub(/^#{self[/\A\s*/]}/, '')
  end
end

module OpsWorks
end
