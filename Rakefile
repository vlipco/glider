# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "glider"
  gem.homepage = "http://github.com/vlipco/glider"
  gem.license = "MIT"
  gem.summary = "Minimal opinionated wrapper around SimpleWorkflow"
  gem.description = "Minimal opinionated wrapper around SimpleWorkflow"
  gem.email = "david@vlipco.co"
  gem.authors = ["David Pelaez"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

#require 'rake/testtask'
#Rake::TestTask.new(:test) do |test|
#  test.libs << 'lib' << 'test'
#  test.pattern = 'test/**/test_*.rb'
#  test.verbose = true
#end
#
#task :default => :test