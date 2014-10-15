# encoding: utf-8

require 'bundler'
Bundler.require(:default, :development, :test)

Jeweler::Tasks.new do |gem|
  gem.name = "glider"
  gem.homepage = "http://github.com/vlipco/glider"
  gem.license = "MIT"
  gem.email = "david@vlipco.co"
  gem.authors = ["David Pelaez"]

  gem.files.exclude 'example/'
  gem.files.exclude 'spec/**/*'
  gem.files.exclude 'docs/**/*'
  gem.files.exclude '.rspec'
  gem.files.exclude 'Rakefile'

  gem.summary = "Minimal opinionated wrapper around SimpleWorkflow"
  
  gem.description = "Glider simplifies the usage of Amazon SWF by adopting convention over configuration and exposing a simplified object oriented API seeking to offer Ruby libraries' traditional simplicity while keeping the benefits of SWF like auditability, timers, timeouts and process decoupling."
 
end

Jeweler::RubygemsDotOrgTasks.new

task :repl do
    require 'bundler/setup'
    Bundler.require :default, :development, :test
    require File.expand_path('../lib/glider.rb', __FILE__)
    pry
end