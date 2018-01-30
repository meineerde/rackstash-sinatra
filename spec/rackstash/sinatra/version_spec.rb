# frozen_string_literal: true
#
# Copyright 2017 Holger Just
#
# This software may be modified and distributed under the terms
# of the MIT license. See the LICENSE.txt file for details.

require 'spec_helper'

require 'rackstash/sinatra/version'

RSpec.describe 'Rackstash::Sinatra::Version' do
  it 'has a version number' do
    expect(Rackstash::Sinatra::Version::STRING).to be_a String
    expect(Rackstash::Sinatra::Version::STRING).to equal Rackstash::Sinatra::Version.to_s
  end

  it 'exposes the version as Rackstash:::Sinatra:VERSION' do
    expect(Rackstash::Sinatra::VERSION).to equal Rackstash::Sinatra::Version::STRING
  end

  it 'exposes a gem_version method' do
    expect(Rackstash::Sinatra::Version.gem_version).to be_a Gem::Version
    expect(Rackstash::Sinatra::Version.gem_version.to_s.gsub('.pre.', '-'))
      .to eql Rackstash::Sinatra::VERSION
  end
end
