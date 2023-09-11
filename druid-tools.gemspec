# frozen_string_literal: true

Gem::Specification.new do |gem|
  gem.authors       = ['Michael Klein', 'Darren Hardy']
  gem.email         = ['mbklein@stanford.edu']
  gem.description   = 'Tools to manipulate DRUID trees and content directories'
  gem.summary       = 'Tools to manipulate DRUID trees and content directories'
  gem.homepage      = 'http://github.com/sul-dlss/druid-tools'
  gem.licenses      = ['ALv2', 'Stanford University Libraries']
  gem.metadata['rubygems_mfa_required'] = 'true'

  gem.required_ruby_version = '>= 3.0'

  gem.files         = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.name          = 'druid-tools'
  gem.require_paths = ['lib']
  gem.version       = File.read('VERSION').strip
end
