# frozen_string_literal: true
#
# Copyright 2017 Holger Just
#
# This software may be modified and distributed under the terms
# of the MIT license. See the LICENSE.txt file for details.

source 'https://rubygems.org'

gemspec name: 'rackstash-sinatra'

def from_env(env, repository)
  case ENV[env]
  when /\d+\.\d/
    "~> #{ENV[env]}"
  when /\A[.\/]/
    { path: File.join(Dir.pwd, ENV[env]) }
  when nil, ''
    nil
  else
    { git: repository, ref: ENV[env] }
  end
end

gem 'rackstash', from_env('RACKSTASH_VERSION', 'https://github.com/meineerde/rackstash.git')
gem 'sinatra', from_env('SINATRA_VERSION', 'https://github.com/sinatra/sinatra.git')
