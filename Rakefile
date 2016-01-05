require 'bundler/gem_tasks'

namespace :test do
  desc 'Run tests'
  task :syntax do
    puts 'Running rubocop'
    sh 'rubocop .'
  end
end

task default: 'test:syntax'
