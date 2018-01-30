# frozen_string_literal: true
#
# Copyright 2017 Holger Just
#
# This software may be modified and distributed under the terms
# of the MIT license. See the LICENSE.txt file for details.

if ENV['COVERAGE']
  require 'simplecov'
  require 'coveralls'

  if ENV['TRAVIS']
    SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
        SimpleCov::Formatter::HTMLFormatter,
        Coveralls::SimpleCov::Formatter
    ]
  else
    SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter
  end

  SimpleCov.start do
    project_name 'Rackstash::Sinatra'
    add_filter '/spec/'
  end
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'rackstash/sinatra'

require_relative 'spec_helper/sinatra_app'

RSpec.configure do |config|
  config.include SpecHelper::SinatraApp

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    # This option should be set when all dependencies are being loaded
    # before a spec run, as is the case in a typical spec helper. It will
    # cause any verifying double instantiation for a class that does not
    # exist to raise, protecting against incorrectly spelt names.
    mocks.verify_doubled_constant_names = true
  end
end
