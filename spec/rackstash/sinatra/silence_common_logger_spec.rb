# frozen_string_literal: true
#
# Copyright 2018 Holger Just
#
# This software may be modified and distributed under the terms
# of the MIT license. See the LICENSE.txt file for details.

require 'spec_helper'

require 'rackstash/sinatra/silence_common_logger'

RSpec.describe Rackstash::Sinatra::SilenceCommonLogger do
  it 'does not patch the class on load' do
    expect(::Rack::CommonLogger).not_to be < described_class
  end

  describe '#apply' do
    before do
      stub_const('::Rack::CommonLogger', Class.new)
    end

    it 'prepends the module' do
      expect(::Rack::CommonLogger)
        .to receive(:prepend).with(described_class)
        .and_call_original

      described_class.apply

      expect(::Rack::CommonLogger).to be < described_class
    end

    it 'prepends the module only once' do
      described_class.apply
      described_class.apply

      expect(::Rack::CommonLogger.ancestors.count { |m| m == described_class })
        .to eql 1
    end
  end

  describe '#log' do
    before do
      stub_const('::Rack::CommonLogger', ::Rack::CommonLogger.clone)
      described_class.apply
    end

    let(:app) { ->(env) { [200, {}, ['OK']] } }
    let(:rackstash) { ::Rackstash::Logger.new(nil) }
    let(:stdout) { StringIO.new }

    context 'with a Rackstash logger present' do
      it 'is silent' do
        rack = ::Rack::Lint.new(
          ::Rack::CommonLogger.new(Rackstash::Sinatra::Middleware.new(app, rackstash), stdout)
        )
        ::Rack::MockRequest.new(rack).get('/')

        expect(stdout.string).to eql ''
      end
    end

    context 'with no Rackstash logger present' do
      it 'logs the request' do
        rack = ::Rack::Lint.new(
          ::Rack::CommonLogger.new(app, stdout)
        )
        ::Rack::MockRequest.new(rack).get('/')

        expect(stdout.string).to match %r{\A- - - \[.+\] "GET / " 200 - 0\.\d+\n\z}
      end
    end
  end
end
