# encoding: utf-8

require 'bundler/gem_tasks'
require 'viiite'
require 'rspec'


task :benchmark => :spec do
  args = %w[report -h --regroup=type,bench spec/benchmark.rb]
  Viiite::Command.run(args)
end

task :spec do
  RSpec::Core::Runner.run(%w[spec])
end