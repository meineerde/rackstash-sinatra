# frozen_string_literal: true
#
# Copyright 2017 - 2018 Holger Just
#
# This software may be modified and distributed under the terms
# of the MIT license. See the LICENSE.txt file for details.

require 'spec_helper'

require 'stringio'

require 'rackstash/sinatra'
require 'sinatra/base'

RSpec.describe Rackstash::Sinatra do
  let(:env) { Rack::MockRequest.env_for('/', method: 'GET') }

  let(:sinatra_base) { Sinatra::Application }
  let(:app) {
    sinatra_app(sinatra_base) do
      get '/' do
        logger.warn('Hello')
      end
    end
  }

  describe '.registered' do
    it 'includes the module' do
      expect(app.extensions).to include described_class
      expect(app.singleton_class.included_modules).to include described_class
    end

    it 'sets default settings' do
      expect(app.rackstash).to equal STDOUT
      expect(app.rackstash_request_fields).to be_nil
      expect(app.rackstash_request_tags).to be_nil
      expect(app.rackstash_response_fields).to be_nil
      expect(app.rackstash_response_tags).to be_nil
    end
  end

  def perform_request
    status, _headers, body = app.call(env)
    body.close if body.respond_to?(:close)

    status
  end

  context 'when inheriting from Sinatra::Base' do
    let(:sinatra_base) { Sinatra::Base }

    it 'sets up a null-logger by default' do
      expect(perform_request).to eql 200

      expect(app).not_to be_logging
      expect(env['rack.logger']).to be_a Rackstash::Logger
      expect(env['rack.logger'].flows.first.adapter).to be_a Rackstash::Adapter::Null
    end

    it 'logs to STDOUT when enabling logging' do
      stdout = StringIO.new
      stub_const("::STDOUT", stdout)

      app.enable :logging

      expect(perform_request).to eql 200
      expect(stdout.string).to match %r|\A{.+"message":"Hello\\n".+}\n\z|
    end

    it 'uses INFO level by default' do
      perform_request

      expect(env['rack.logger']).to be_a Rackstash::Logger
      expect(env['rack.logger'].flows.first.adapter).to be_a Rackstash::Adapter::Null

      expect(env['rack.logger'].level).to eql 1
    end
  end

  context 'when inheriting from Sinatra::Application' do
    let(:sinatra_base) { Sinatra::Application }

    it 'logs to STDOUT' do
      stdout = StringIO.new
      stub_const("::STDOUT", stdout)
      # This is enabled for non-test environments by default
      app.enable :logging

      expect(perform_request).to eql 200
      expect(env['rack.logger']).to be_a Rackstash::Logger
      expect(env['rack.logger'].flows.first.adapter).to be_a Rackstash::Adapter::IO

      expect(stdout.string).to match %r|\A{.+"message":"Hello\\n".+}\n\z|
    end

    it 'uses INFO level by default' do
      stdout = StringIO.new
      stub_const("::STDOUT", stdout)
      # This is enabled for non-test environments by default
      app.enable :logging

      perform_request

      expect(env['rack.logger']).to be_a Rackstash::Logger
      expect(env['rack.logger'].flows.first.adapter).to be_a Rackstash::Adapter::IO

      expect(env['rack.logger'].level).to eql 1
    end
  end

  describe '.logging' do
    it 'can disable rackstash logging' do
      app.disable :logging

      perform_request

      expect(env['rack.logger']).to be_a Rackstash::Logger
      expect(env['rack.logger'].flows.first.adapter).to be_a Rackstash::Adapter::Null
    end

    it 'sets the log level' do
      stub_const("::STDOUT", StringIO.new)
      app.set :logging, Rackstash::DEBUG

      perform_request

      expect(env['rack.logger']).to be_a Rackstash::Logger
      expect(env['rack.logger'].level).to eql 0
    end
  end

  describe '.rackstash' do
    it 'logs to STDOUT by default' do
      stdout = StringIO.new
      stub_const("::STDOUT", stdout)
      # This is enabled for non-test environments by default
      app.enable :logging

      expect(perform_request).to eql 200
      expect(stdout.string).to match %r|\A{.+"message":"Hello\\n".+}\n\z|
    end

    it 'can set a different target' do
      stream = StringIO.new

      app.rackstash = stream
      app.enable :logging

      expect(perform_request).to eql 200
      expect(stream.string).to match %r|\A{.+"message":"Hello\\n".+}\n\z|
    end

    it 'can set a different logger' do
      stream = StringIO.new
      logger = Rackstash::Logger.new(stream)

      app.rackstash = logger
      app.enable :logging

      expect(logger).to receive(:warn).with('Hello').and_call_original

      expect(perform_request).to eql 200
      expect(env['rack.logger']).to equal logger
      expect(stream.string).to match %r|\A{.+"message":"Hello\\n".+}\n\z|
    end
  end

  context 'with additional fields' do
    let(:logs) { [] }

    before do
      app.rackstash = Rackstash::Logger.new(->(event) { logs << event })
      app.enable :logging
    end

    it 'adds additional request_fields' do
      app.rackstash_request_fields = { 'zombie' => 'groan', :robot => 1001001 }
      perform_request

      expect(logs.count).to eql 1
      expect(logs.first).to include 'zombie' => 'groan', 'robot' => 1001001
    end

    it 'provides a Rack::Request object to request_fields' do
      app.rackstash_request_fields = {
        'scope_class' => ->(request) { request.class.name },
      }
      perform_request

      expect(logs.count).to eql 1
      expect(logs.first).to include 'scope_class' => 'Rack::Request'
    end

    it 'adds additional request_tags' do
      app.rackstash_request_tags = ['foo', :bar, 123]
      perform_request

      expect(logs.count).to eql 1
      expect(logs.first).to include 'tags' => ['foo', 'bar', '123']
    end

    it 'provides a Rack::Request object to rackstash_request_tags' do
      app.rackstash_request_tags = [
        'foo',
        ->(request) { request.class.name }
      ]
      perform_request

      expect(logs.count).to eql 1
      expect(logs.first).to include 'tags' => ['foo', 'Rack::Request']
    end

    it 'adds additional response_fields' do
      app.rackstash_response_fields = { 'response' => 'done' }
      perform_request

      expect(logs.count).to eql 1
      expect(logs.first).to include 'response' => 'done'
    end

    it 'provides the response headers to rackstash_response_fields' do
      app.rackstash_response_fields = {
        'scope_class' => ->(headers) { headers.class.name },
        'content_type' => ->(headers) { headers['Content-Type'] }
      }
      perform_request

      expect(logs.count).to eql 1
      expect(logs.first).to include(
        'scope_class' => 'Rack::Utils::HeaderHash', # a variant of ::Hash
        'content_type' => 'text/html;charset=utf-8'
      )
    end

    it 'adds additional response_tags' do
      app.rackstash_response_tags = ['tweet', :moo]
      perform_request

      expect(logs.count).to eql 1
      expect(logs.first).to include 'tags' => ['tweet', 'moo']
    end

    it 'provides the response headers to rackstash_response_tags' do
      app.rackstash_response_tags = [
        ->(headers) { headers['Content-Type'][/\w+/] },
        'request'
      ]
      perform_request

      expect(logs.count).to eql 1
      expect(logs.first).to include 'tags' => ['text', 'request']
    end
  end
end
