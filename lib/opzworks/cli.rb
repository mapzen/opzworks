require 'trollop'
require 'opzworks'

module OpzWorks
  class CLI
    def self.start
      commands = %w(ssh cmd json berks elastic)

      Trollop.options do
        version "opzworks #{OpzWorks::VERSION} (c) #{OpzWorks::AUTHORS.join(', ')}"
        banner <<-EOS.unindent
          usage: opzworks [COMMAND] [OPTIONS...]

          #{OpzWorks::SUMMARY}

          Commands
            ssh  #{OpzWorks::Commands::SSH.banner}
            cmd  #{OpzWorks::Commands::CMD.banner}
            json #{OpzWorks::Commands::JSON.banner}
            berks #{OpzWorks::Commands::BERKS.banner}
            elastic #{OpzWorks::Commands::ELASTIC.banner}

          For help with specific commands, run:
            opzworks COMMAND -h/--help

          Options:
        EOS
        stop_on commands
      end

      command = ARGV.shift
      case command
      when 'ssh'
        OpzWorks::Commands::SSH.run
      when 'json'
        OpzWorks::Commands::JSON.run
      when 'berks'
        OpzWorks::Commands::BERKS.run
      when 'elastic'
        OpzWorks::Commands::ELASTIC.run
      when 'cmd'
        OpzWorks::Commands::CMD.run
      when nil
        Trollop.die 'no command specified'
      else
        Trollop.die "unknown command: #{command}"
      end
    end
  end
end
