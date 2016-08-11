# -*- encoding: utf-8 -*-
$LOAD_PATH.push File.expand_path("../lib", __FILE__)
require "fig_tree/version"

Gem::Specification.new do |s|
  s.name        = "fig_fig"
  s.version     = FigTree::VERSION
  s.date        = "2016-08-09"
  s.summary     = "Ruby Application Configurator"
  s.description = "Configurator for Ruby Applications with some validation and sugars."
  s.authors     = ["Courtland Caldwell", "Blake Luchessi"]
  s.email       = "engineering@mattermark.com"
  s.files         = `git ls-files`.split("\n") - %w[Gemfile Gemfile.lock]
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.license = "MIT"
  s.homepage =
    "https://github.com/Referly/fig_tree"
  s.add_development_dependency "rspec", "~> 3.2"
  s.add_development_dependency "rb-readline", "~> 0.5", ">= 0.5.3"
  s.add_development_dependency "byebug", "~> 3.5"
  s.add_development_dependency "simplecov", "~> 0.10"
  s.add_development_dependency "rubocop", "~> 0.31"
  s.add_development_dependency "rspec_junit_formatter", "~> 0.2"
end
