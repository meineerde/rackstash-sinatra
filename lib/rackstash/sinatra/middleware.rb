# frozen_string_literal: true
#
# Copyright 2018 Holger Just
#
# This software may be modified and distributed under the terms
# of the MIT license. See the LICENSE.txt file for details.

require 'rackstash/rack/middleware'

module Rackstash
  module Sinatra
    # This class behaves exactly like `Rackstash::Rack::Middleware` with the
    # notable exception that we explicitly set any Sinatra::CommonLogger
    # middlewares in the same middleware chain to be silent (i.e. to not log
    # anything). This helps us to avoid doubled logs produced by different
    # logging middlewares.
    class Middleware < ::Rackstash::Rack::Middleware
      private

      # Set the `sinatra.commonlogger` variable to `true` in the Rack
      # environment before passing the request to lowwer middlewares and the
      # app. This ensures that any `::Rack::CommonLogger` instances (as well as
      # all `::Sinatra::CommonLogger` instances) in the same middleware stack
      # will become silent and not log anything. This is required, so that a
      # single request is not logged multiple times even in the face of the
      # default Rack middleware stack.
      #
      # @param env [Hash] the rack environment
      # @return [void]
      def on_request(env)
        env['sinatra.commonlogger'] = true
        super
      end
    end
  end
end
