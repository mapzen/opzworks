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
      file = ENV['AWS_CONFIG_FILE'] || "#{ENV['HOME']}/.aws/config"

      fail 'AWS config file not found!'.foreground(:red) unless File.exist? file
      ini = IniFile.load(file)

      # set the region and the profile we want to pick up from ~/.aws/credentials
      @aws_profile = ENV['AWS_PROFILE'] || 'default'
      @aws_region  = ENV['AWS_REGION'] || ini[@aws_profile]['region']

      @ssh_user_name = ini['opzworks']['ssh-user-name'].strip
      @berks_repository_path = ini['opzworks']['berks-repository-path'].strip

      @berks_base_path =
        ini['opzworks']['berks-base-path'].strip unless ini['opzworks']['berks-base-path'].nil?
      @berks_s3_bucket =
        ini['opzworks']['berks-s3-bucket'].strip unless ini['opzworks']['berks-s3-bucket'].nil?
      @berks_tarball_name =
        ini['opzworks']['berks-tarball-name'].strip unless ini['opzworks']['berks-tarball-name'].nil?
      @berks_github_org =
        ini['opzworks']['berks-github-org'].strip unless ini['opzworks']['berks-github-org'].nil?
    end
  end
end
