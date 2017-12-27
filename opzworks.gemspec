# coding: utf-8
# frozen_string_literal: true

root = File.expand_path('..', __FILE__)
lib = File.expand_path('lib', root)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opzworks/meta'

Gem::Specification.new do |spec|
  spec.name          = 'opzworks'
  spec.version       = OpzWorks::VERSION
  spec.authors       = OpzWorks::AUTHORS
  spec.email         = OpzWorks::EMAIL
  spec.description   = OpzWorks::DESCRIPTION
  spec.summary       = OpzWorks::SUMMARY
  spec.homepage      = 'https://github.com/mapzen/opzworks'
  spec.license       = 'MIT'

  ignores = File.readlines('.gitignore').grep(/\S+/).map(&:chomp)
  spec.files = Dir['**/*'].reject do |f|
    File.directory?(f) || ignores.any? { |i| File.fnmatch(i, f) }
  end
  spec.files += ['.gitignore']

  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'aws-sdk', '~> 2.7'
  spec.add_dependency 'trollop', '~> 2.0'
  spec.add_dependency 'trollop-subcommands'
  spec.add_dependency 'inifile', '~> 3.0.0'
  spec.add_dependency 'diffy',   '~> 3.1.0'
  spec.add_dependency 'rainbow', '~> 2.2.1'
  spec.add_dependency 'faraday', '~> 0.9'
  spec.add_dependency 'net-ssh', '~> 3.0.2'
  spec.add_dependency 'net-ssh-multi', '~> 1.2.1'
  spec.add_dependency 'addressable', '~> 2.5.0'
  spec.add_dependency 'public_suffix', '~> 2.0.4'
  spec.add_dependency 'httpclient', '~> 2.8.2.4'
  spec.add_dependency 'hashie', '~> 3.4.6'
  spec.add_dependency 'nio4r', '~> 1.2.1'
  spec.add_dependency 'chef-config', '~> 12.16.42'
  spec.add_dependency 'json', '~> 1.8'
  spec.add_dependency 'berkshelf-api-client'
  spec.add_dependency 'cleanroom'
  spec.add_dependency 'minitar', '~> 0.5.4'
  spec.add_dependency 'mixlib-archive', '~> 0.2.0'
  spec.add_dependency 'octokit', '~> 4.6'
  spec.add_dependency 'sawyer', '~> 0.8'
  spec.add_dependency 'solve', '~> 3.0.1'
  spec.add_dependency 'molinillo', '~> 0.5.4'
  spec.add_dependency 'thor', '~> 0.19'
  spec.add_dependency 'berkshelf'

  spec.add_development_dependency 'rubocop', '~> 0.37'
  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'awesome_print'
  spec.add_development_dependency 'byebug'
end
