# frozen_string_literal: true

require 'simplecov'
require 'tmpdir' # Dir.mktmpdir
SimpleCov.start do
  add_filter 'spec'
end

require 'bundler/setup'
Bundler.require(:default, :development)
