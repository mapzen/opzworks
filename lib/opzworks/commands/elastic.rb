# frozen_string_literal: true

require 'aws-sdk-opsworks'
require 'trollop'
require 'faraday'
require 'opzworks'
require 'net/ssh'
require 'net/ssh/multi'
require 'rainbow/ext/string'

require_relative 'include/elastic'

module OpzWorks
  class Commands
    class ELASTIC
      def self.banner
        'Perform operations on an Elastic cluster'
      end

      def self.run options

        ARGV.empty? ? Trollop.die('no stacks specified') : false

        optarr = []
        options.each do |opt, val|
          val == true ? optarr << opt : false
        end
        optarr.empty? ? Trollop.die('no options specified') : false

        config = OpzWorks.config
        @client = Aws::OpsWorks::Client.new(region: config.aws_region, profile: config.aws_profile)
        response = @client.describe_stacks

        # loops over inputs
        ARGV.each do |opt|
          var = if options[:start]
                  es_get_input(opt, response, 'start')
                else
                  es_get_input(opt, response)
                end
          next if var == false

          options[:old_service_name] ? @service_name = 'elasticsearch' : false

          case options[:rolling]
          when true
            # cycle through all the hosts, waiting for status
            @ip_addrs.each do |ip|
              puts "\n________________________________________________"
              puts "Now operating on host #{ip}".foreground(:yellow)

              if @disable_shard_allocation
                es_enable_allocation(ip, 'none')
                sleep 2
              end

              es_service('restart', [ip], @service_name)
              es_wait_for_status(ip, 'yellow')
              es_enable_allocation(ip, 'all') if @disable_shard_allocation
              es_wait_for_status(ip, 'green')
            end
          end

          case options[:start]
          when true
            es_service('start', @ip_addrs, @service_name)

            @ip_addrs.each do |ip|
              es_wait_for_status(ip, 'green')
            end
          end

          case options[:stop]
          when true
            # use the first host to disable shard allocation
            if @disable_shard_allocation
              es_enable_allocation(@ip_addrs.first, 'none')
              sleep 2
            end

            es_service('stop', @ip_addrs, @service_name)
          end

          case options[:bounce]
          when true
            # use the first host to disable shard allocation
            if @disable_shard_allocation
              es_enable_allocation(@ip_addrs.first, 'none')
              sleep 2
            end

            es_service('restart', @ip_addrs, @service_name)

            es_wait_for_status(@ip_addrs.first, 'yellow')
            es_enable_allocation(@ip_addrs.first, 'all') if @disable_shard_allocation
            es_wait_for_status(@ip_addrs.first, 'green')
          end
        end
      end
    end
  end
end
