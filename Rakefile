# encoding: utf-8

require 'bundler'
Bundler.require(:default, :development, :test)


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

task :repl do
    require File.expand_path('../lib/glider.rb', __FILE__)
    pry
end