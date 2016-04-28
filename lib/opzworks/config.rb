# frozen_string_literal: true

require 'inifile'
require 'rainbow'

module OpzWorks
  def self.config
    @config ||= Config.new
  end

  class Config
    attr_reader :ssh_user_name, :berks_repository_path, :aws_region, :aws_profile,
                :berks_base_path, :berks_s3_bucket, :berks_tarball_name, :berks_github_org

    def initialize
      aws_config_file = ENV['AWS_CONFIG_FILE'] || "#{ENV['HOME']}/.aws/config"
      opzworks_config_file = ENV['OPZWORKS_CONFIG_FILE'] || "#{ENV['HOME']}/.opzworks/config"

      # abort unless required conditions are met
      abort "AWS config file #{aws_config_file} not found, exiting!".foreground(:red) unless File.exist? aws_config_file
      abort "Opzworks config file #{opzworks_config_file} not found, exiting!".foreground(:red) unless File.exist? opzworks_config_file
      aws_ini = IniFile.load(aws_config_file)
      opzworks_ini = IniFile.load(opzworks_config_file)

      @opzworks_profile = ENV['OPZWORKS_PROFILE'] || 'default'
      abort "Could not find [#{@opzworks_profile}] config block in #{opzworks_config_file}, exiting!".foreground(:red) if opzworks_ini[@opzworks_profile].empty?

      # set the region and the profile we want to pick up from ~/.aws/credentials
      @aws_profile = ENV['AWS_PROFILE'] || 'default'
      abort "Could not find [#{@aws_profile}] config block in #{aws_config_file}, exiting!".foreground(:red) if aws_ini[@aws_profile].empty?
      @aws_region = ENV['AWS_REGION'] || aws_ini[@aws_profile]['region']

      @ssh_user_name =
        opzworks_ini[@opzworks_profile]['ssh-user-name'].strip unless opzworks_ini[@opzworks_profile]['ssh-user-name'].nil?
      @berks_repository_path =
        opzworks_ini[@opzworks_profile]['berks-repository-path'].strip unless opzworks_ini[@opzworks_profile]['berks-repository-path'].nil?
      @berks_base_path =
        opzworks_ini[@opzworks_profile]['berks-base-path'].strip unless opzworks_ini[@opzworks_profile]['berks-base-path'].nil?
      @berks_s3_bucket =
        opzworks_ini[@opzworks_profile]['berks-s3-bucket'].strip unless opzworks_ini[@opzworks_profile]['berks-s3-bucket'].nil?
      @berks_tarball_name =
        opzworks_ini[@opzworks_profile]['berks-tarball-name'].strip unless opzworks_ini[@opzworks_profile]['berks-tarball-name'].nil?
      @berks_github_org =
        opzworks_ini[@opzworks_profile]['berks-github-org'].strip unless opzworks_ini[@opzworks_profile]['berks-github-org'].nil?
    end
  end
end
