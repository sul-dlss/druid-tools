#$LOAD_PATH.unshift(File.expand_path('../../lib',__FILE__))

require 'coveralls'
Coveralls.wear_merged! # because we run travis on multiple rubies

require 'simplecov'
SimpleCov.formatter = Coveralls::SimpleCov::Formatter
SimpleCov.start do
  add_filter 'spec'
end

require 'bundler/setup'
Bundler.require(:default, :development)
