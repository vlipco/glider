# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: glider 0.1.5 ruby lib

Gem::Specification.new do |s|
  s.name = "glider"
  s.version = "0.1.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["David Pelaez"]
  s.date = "2013-11-26"
  s.description = "Minimal opinionated wrapper around SimpleWorkflow"
  s.email = "david@vlipco.co"
  s.files = [
    "Gemfile",
    "Gemfile.lock",
    "Rakefile",
    "VERSION",
    "docs/event_names.md",
    "examples/Gemfile",
    "examples/Gemfile.lock",
    "examples/activity.rb",
    "examples/shared_boot.rb",
    "examples/trigger.rb",
    "examples/workflow.rb",
    "glider.gemspec",
    "lib/glider.rb",
    "lib/glider/activities.rb",
    "lib/glider/component.rb",
    "lib/glider/process_manager.rb",
    "lib/glider/utils.rb",
    "lib/glider/workflows.rb",
    "readme.md"
  ]
  s.homepage = "http://github.com/vlipco/glider"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "2.1.9"
  s.summary = "Minimal opinionated wrapper around SimpleWorkflow"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<aws-sdk>, [">= 0"])
      s.add_runtime_dependency(%q<activesupport>, [">= 4.0.0"])
      s.add_runtime_dependency(%q<json>, [">= 0"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.8.7"])
    else
      s.add_dependency(%q<aws-sdk>, [">= 0"])
      s.add_dependency(%q<activesupport>, [">= 4.0.0"])
      s.add_dependency(%q<json>, [">= 0"])
      s.add_dependency(%q<bundler>, ["~> 1.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.8.7"])
    end
  else
    s.add_dependency(%q<aws-sdk>, [">= 0"])
    s.add_dependency(%q<activesupport>, [">= 4.0.0"])
    s.add_dependency(%q<json>, [">= 0"])
    s.add_dependency(%q<bundler>, ["~> 1.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.8.7"])
  end
end

