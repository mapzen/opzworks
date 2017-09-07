# frozen_string_literal: true

require 'inifile'
require 'rainbow'
require 'yaml'

module OpzWorks
  def self.config pre_config, aws_region = nil
    @config ||= Config.new pre_config, aws_region
  end

  class Config
    attr_reader :pre_config, :ssh_user_name, :berks_repository_user, :berks_repository_path,
                :berks_path, :berks_s3_bucket, :berks_tarball_base_name, :berks_github_org,
                :aws_region, :aws_profile, :aws_credentials_path, :aws_access_key, :aws_secret_access_key,
                :chef_branch, :is_local_branch, :app_path, :aws_app_id

    def initialize pre_config, aws_region
      aws_config_file = ENV['AWS_CONFIG_FILE'] || "#{ENV['HOME']}/.aws/config"
      opzworks_config_file = ENV['OPZWORKS_CONFIG_FILE'] || "#{ENV['HOME']}/.opzworks/config"

      # abort unless required conditions are met
      abort "AWS config file #{aws_config_file} not found, exiting!".foreground(:red) unless File.exist? aws_config_file
      abort "Opzworks config file #{opzworks_config_file} not found, exiting!".foreground(:red) unless File.exist? opzworks_config_file
      aws_ini = IniFile.load(aws_config_file)
      opzworks_ini = IniFile.load(opzworks_config_file)

      @opzworks_profile = ENV['OPZWORKS_PROFILE'] || 'default'
      abort "Could not find [#{@opzworks_profile}] config block in #{opzworks_config_file}, exiting!".foreground(:red) if opzworks_ini[@opzworks_profile].empty?

      if pre_config[:chef]
        if pre_config[:chef][:chef_branch]
          @chef_branch = pre_config[:chef][:chef_branch]
        elsif pre_config[:chef][:chef_branch_to]
          @chef_branch = pre_config[:chef][:chef_branch_to]
        end

        @chef_branch_from = pre_config[:chef][:chef_branch_from] unless pre_config[:chef][:chef_branch_from].nil?
        @is_local_branch = pre_config[:chef][:is_local_branch]
      end

      berks_path = pre_config[:chef] ? pre_config[:chef][:berks_path] : nil

      @berks_path =
        berks_path || opzworks_ini[@opzworks_profile]['berks-path'].strip unless opzworks_ini[@opzworks_profile]['berks-path'].nil?
      @berks_repository_protocol =
        (opzworks_ini[@opzworks_profile]['berks-repository-protocol'].strip unless opzworks_ini[@opzworks_profile]['berks-repository-protocol'].nil?)
      @berks_repository_user =
        opzworks_ini[@opzworks_profile]['berks-repository-user'].strip unless opzworks_ini[@opzworks_profile]['berks-repository-user'].nil?
      @berks_repository_path =
        opzworks_ini[@opzworks_profile]['berks-repository-path'].strip unless opzworks_ini[@opzworks_profile]['berks-repository-path'].nil?
      @berks_s3_bucket =
        opzworks_ini[@opzworks_profile]['berks-s3-bucket'].strip unless opzworks_ini[@opzworks_profile]['berks-s3-bucket'].nil?
      @berks_tarball_base_name =
        opzworks_ini[@opzworks_profile]['berks-tarball-base-name'].strip unless opzworks_ini[@opzworks_profile]['berks-tarball-base-name'].nil?

      # set the region and the profile we want to pick up from ~/.aws/credentials
      @aws_profile = ENV['AWS_PROFILE'] || 'default'
      abort "Could not find [#{@aws_profile}] config block in #{aws_config_file}, exiting!".foreground(:red) if aws_ini[@aws_profile].empty?

      if pre_config[:app]
        @aws_app_id = aws_ini[@aws_profile]["app-id-#{pre_config[:app][:environment]}"].strip unless aws_ini[@aws_profile]['app-id'].nil?
        @app_path =
          opzworks_ini[@opzworks_profile]['app-path'].strip unless opzworks_ini[@opzworks_profile]['app-path'].nil?
      end

      if aws_region.nil?
        @aws_region = ENV['AWS_REGION'] || aws_ini[@aws_profile]['region']
      else
        @aws_region = aws_region
      end

      @aws_credentials_path =
        opzworks_ini[@opzworks_profile]['aws-credentials-path'].strip unless opzworks_ini[@opzworks_profile]['aws-credentials-path'].nil?

      if @aws_credentials_path
        @aws_credentials_from_env =
          opzworks_ini[@opzworks_profile]['aws-credentials-from-env'].strip unless opzworks_ini[@opzworks_profile]['aws-credentials-from-env'].nil?

        appyml = YAML.load_file(@aws_credentials_path)

        if @aws_credentials_from_env && !appyml[@aws_credentials_from_env].nil?
          @aws_access_key = appyml[@aws_credentials_from_env]['AWS_ACCESS_KEY_ID']
          @aws_secret_access_key = appyml[@aws_credentials_from_env]['AWS_SECRET_ACCESS_KEY']
        elsif !@aws_credentials_from_env
          @aws_access_key = appyml['AWS_ACCESS_KEY_ID']
          @aws_secret_access_key = appyml['AWS_SECRET_ACCESS_KEY']
        end

        if @aws_access_key.nil? || @aws_secret_access_key.nil?
          abort "Could not get aws credentials from file #{@aws_credentials_path}".foreground(:red)
        end
      end

      @ssh_user_name =
        opzworks_ini[@opzworks_profile]['ssh-user-name'].strip unless opzworks_ini[@opzworks_profile]['ssh-user-name'].nil?
      end
  end
end
