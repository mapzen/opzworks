require 'opzworks/meta'
require 'opzworks/config'
require 'opzworks/commands/ssh'
require 'opzworks/commands/json'
require 'opzworks/commands/berks'

class String
  def unindent
    gsub(/^#{self[/\A\s*/]}/, '')
  end
end

module OpsWorks
end
