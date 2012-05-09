#!/usr/bin/env rake
require "bundler/gem_tasks"

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

require 'dlss/rake/dlss_release'
Dlss::Release.new

task :default => :spec