# frozen_string_literal: true
#
# Copyright 2018 Holger Just
#
# This software may be modified and distributed under the terms
# of the MIT license. See the LICENSE.txt file for details.

begin
  # rack >= 2.0 (used by sinatra >= 2.0)
  require 'rack/common_logger'
rescue LoadError
  # rack ~> 1.0 (used by sinatra ~> 1.0)
  require 'rack/commonlogger'
end

module Rackstash
  module Sinatra
    # When applied, this module is prepended to the `Rack::CommonLogger` class.
    # It modifies its behavior to not log anything if there is a
    # `Rackstash::Rack::Middleware` somewhere in the same middleware stack.
    #
    # This is unfortunately required since Rack builds a default middleware
    # stack which already includes a `Rack::CommonLogger` in most cases when
    # running in the `deployment` or `development` environments. However, since
    # the rackstash middleware already logs request details (and thus takes the
    # place of the default `CommonLogger`), it is not desirable to log the
    # same information again.
    module SilenceCommonLogger
      # Apply the patch by prepending this module to the `::Rack::CommonLogger`
      # class. If the module is already prepended, this does nothing.
      #
      # @return [void]
      def self.apply
        ::Rack::CommonLogger.prepend self unless ::Rack::CommonLogger < self
      end

      # This method overwrites the existing method of the same name on
      # `::Rack::CommonLogger`. If we have an active
      # `Rackstash::Sinatra::Middleware` in the middleware stack, we modify the
      # `CommonLogger` to not log anything. If there is no Rackstash middleware,
      # we are not changing anything and allow the CommonLogger to do its duty.
      #
      # @param env [Hash] The rack environment of the current request
      # @param args [Array] Any further arguments passed to the original method
      # @return [void] the return value of the original `log` method or `nil`
      def log(env, *args)
        unless env['sinatra.commonlogger'.freeze] &&
               env['rackstash.logger'.freeze].is_a?(::Rackstash::Logger)
          super
        end
      end
    end
  end
end

