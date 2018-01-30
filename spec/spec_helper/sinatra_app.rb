# frozen_string_literal: true
#
# Copyright 2018 Holger Just
#
# This software may be modified and distributed under the terms
# of the MIT license. See the LICENSE.txt file for details.

module SpecHelper
  module SinatraApp
    def sinatra_app(base_class = ::Sinatra::Base, &block)
      Class.new(base_class) do
        register Rackstash::Sinatra

        if block_given?
          if block.arity == 0
            instance_eval(&block)
          else
            yield self
          end
        end
      end
    end
  end
end
