require 'opzworks/meta'
require 'opzworks/config'

# require our commands
COMMANDS = %w(ssh cmd json berks elastic).each do |cmd|
  require "opzworks/commands/#{cmd}"
end

class String
  def unindent
    gsub(/^#{self[/\A\s*/]}/, '')
  end
end

module OpsWorks
end
