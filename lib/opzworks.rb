require 'opzworks/meta'
require 'opzworks/config'

# require our commands
@commands = %w(ssh json berks elastic)
@commands.each do |cmd|
  require "opzworks/commands/#{cmd}"
end

class String
  def unindent
    gsub(/^#{self[/\A\s*/]}/, '')
  end
end

module OpsWorks
end
