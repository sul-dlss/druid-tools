# -*- encoding: utf-8 -*-
require File.expand_path('../lib/druid_tools/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Michael Klein"]
  gem.email         = ["mbklein@stanford.edu"]
  gem.description   = %q{Tools to manipulate DRUID trees and content directories}
  gem.summary       = %q{Tools to manipulate DRUID trees and content directories}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "druid-tools"
  gem.require_paths = ["lib"]
  gem.version       = DruidTools::VERSION
  
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'lyberteam-devel'
end
