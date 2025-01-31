# frozen_string_literal: true

require 'simplecov'
require 'tmpdir' # Dir.mktmpdir
SimpleCov.start do
  add_filter 'spec'

  if ENV['CI']
    require 'simplecov_json_formatter'

    formatter SimpleCov::Formatter::JSONFormatter
  end
end

require 'bundler/setup'
Bundler.require(:default, :development)
