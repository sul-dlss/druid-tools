# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.authors       = ['Michael Klein', 'Darren Hardy']
  gem.email         = ['mbklein@stanford.edu']
  gem.description   = 'Tools to manipulate DRUID trees and content directories'
  gem.summary       = 'Tools to manipulate DRUID trees and content directories'
  gem.homepage      = 'http://github.com/sul-dlss/druid-tools'
  gem.licenses      = ['ALv2', 'Stanford University Libraries']
  gem.has_rdoc      = true

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^spec/})
  gem.name          = 'druid-tools'
  gem.require_paths = ['lib']
  gem.version       = File.read('VERSION').strip
  
  gem.add_development_dependency 'rake', '>= 10.1.0'
  gem.add_development_dependency 'rspec', '>= 2.14.0'
end
