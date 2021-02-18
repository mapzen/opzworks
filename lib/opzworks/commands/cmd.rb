# frozen_string_literal: true

require 'aws-sdk-opsworks'
require 'trollop'
require 'opzworks'
require 'rainbow/ext/string'

module OpzWorks
  class Commands
    class CMD
      def self.banner
        'Run various OpsWorks commands'
      end

      def self.run options
        config = OpzWorks.config
        client = Aws::OpsWorks::Client.new(region: config.aws_region, profile: config.aws_profile)

        if options[:'list-stacks']
          list = []
          response = client.describe_stacks
          response[:stacks].each { |stack| list << stack[:name] }

          puts list.sort
        else
          puts 'No options specified'.foreground(:yellow)
        end
      end
    end
  end
end
