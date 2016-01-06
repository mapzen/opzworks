# coding: utf-8

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

  spec.add_dependency 'aws-sdk', '~> 2.2.7'
  spec.add_dependency 'trollop', '~> 2.0'
  spec.add_dependency 'inifile', '~> 2.0.2'
  spec.add_dependency 'rubocop', '~> 0.35.0'
  spec.add_dependency 'diffy',   '~> 3.1.0'
  spec.add_dependency 'rainbow', '~> 2.0.0'
  spec.add_dependency 'faraday', '~> 0.9.2'
  spec.add_dependency 'net-ssh', '~> 3.0.1'
  spec.add_dependency 'net-ssh-multi', '~> 1.2.1'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'awesome_print'
end
