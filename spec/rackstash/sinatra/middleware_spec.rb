# frozen_string_literal: true
#
# Copyright 2017 Holger Just
#
# This software may be modified and distributed under the terms
# of the MIT license. See the LICENSE.txt file for details.

require 'spec_helper'

require 'rackstash/sinatra/middleware'

RSpec.describe Rackstash::Sinatra::Middleware do
  let(:logger) { Rackstash::Logger.new }

  it 'is a Rackstash::Rack::Middleware' do
    expect(described_class).to be < Rackstash::Rack::Middleware
  end

  it 'sets sinatra.commonlogger' do
    called = false

    app = lambda { |env|
      expect(env['sinatra.commonlogger']).to eql true

      called = true
      [200, {}, ['OK']]
    }
    rack = ::Rack::Lint.new(described_class.new(app, logger))
    ::Rack::MockRequest.new(rack).get('/')

    expect(called).to eql true
  end

  it 'sets rackstash.logger' do
    called = false

    app = lambda { |env|
      expect(env['rackstash.logger']).to equal logger

      called = true
      [200, {}, ['OK']]
    }
    rack = ::Rack::Lint.new(described_class.new(app, logger))
    ::Rack::MockRequest.new(rack).get('/')

    expect(called).to eql true
  end

end
