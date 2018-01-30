# frozen_string_literal: true
#
# Copyright 2017 - 2018 Holger Just
#
# This software may be modified and distributed under the terms
# of the MIT license. See the LICENSE.txt file for details.

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rackstash/sinatra/version'

Gem::Specification.new do |spec|
  spec.name          = 'rackstash-sinatra'
  spec.version       = Rackstash::Sinatra::VERSION
  spec.authors       = ['Holger Just']

  spec.summary       = 'Sinatra integration for Rackstash'
  spec.description   = <<-TXT.gsub(/\s+|\n/, ' ').strip
  Integrate Rackstash into your Sinatra application to provide unified and
  flexible logs for each request. You can add additional data to each log event
  which provides increased observability into your app. Using a log server like
  Logstash or Graylog, you can store, query and analyze the logs.
  TXT
  spec.homepage      = 'https://github.com/meineerde/rackstash-sinatra'
  spec.license       = 'MIT'

  files = `git ls-files -z`.split("\x0")
  spec.files         = files.reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.1.0'

  spec.add_dependency 'rackstash', '~> 0.2.0-dev'
  spec.add_dependency 'sinatra'

  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'

  spec.add_development_dependency 'coveralls', '~> 0.8.20'
  spec.add_development_dependency 'yard', '~> 0.9'
end
