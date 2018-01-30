# frozen_string_literal: true
#
# Copyright 2017 - 2018 Holger Just
#
# This software may be modified and distributed under the terms
# of the MIT license. See the LICENSE.txt file for details.

require 'rackstash/rack'

require 'rackstash/sinatra/middleware'
require 'rackstash/sinatra/silence_common_logger'
require 'rackstash/sinatra/version'

module Rackstash
  # This module defines the integration of Rackstash into Sinatra as a Sinatra
  # plugin. When registering this plugin in your Sinatra app, we will setup a
  # Rack middleware to provide a logger to each request handled by Sinatra. You
  # can use this logger the same way you can with the original Rack logger.
  #
  # All messages logged to the logger during the request will be captured in a
  # Buffer and (by default) logged as a single log event after the response was
  # sent.
  #
  # To use the Rackstash integration, you have to register the plugin in your
  # Sinatra application:
  #
  #     require 'rackstash/sinatra'
  #     register Rackstash::Sinatra
  #
  #     # Optionally set the log target. By default, we'll write JSON logs to STDOUT
  #     set :rackstash, "log/#{environment}.log"
  #
  #     get '/' do
  #       logger.info 'Starting request...'
  #       "Hello world!"
  #     end
  #
  # or when using the modular Sinatra application style:
  #
  #     require 'rackstash/sinatra'
  #
  #     class MySinatraApp < Sinatra::Base
  #       register Rackstash::Sinatra
  #
  #       # Logging is enabled by default when inheriting from Sinatra::Application
  #       enable :logging
  #
  #       # Optionally set the log target. By default, we'll write JSON logs to STDOUT
  #       set :rackstash, "log/#{environment}.log"
  #
  #       get '/' do
  #         logger.info 'Starting request...'
  #         "Hello world!"
  #       end
  #     end
  #
  # Note that in any case, we will only log to Rackstash if both `logging` is
  # enabled and the `rackstash` setting is set to a a value other than `false`.
  #
  # To further configure the Rackstash logger, we add the following
  # configuration settings to the application when you register the
  # `Rackstash::Sinatra` plugin:
  #
  # * `rackstash => Rackstash::Logger, Object, nil` - the logger or log target
  #   of the logging middleware. When setting this to `false`, Rackstash
  #   integration will be disabled and Sinatra's default logging settings will
  #   be used. When setting it to a `Rackstash::Logger` object, we use it
  #   it directly. In all other cases, we assume the given value is a log device
  #   (e.g. an `IO` object or the name of a log file) which can be used to
  #   create a suitable Rackstash adapter with a new `Rackstash::Logger` object
  #   for use by the middleware.
  # * `rackstash_buffering => Symbol, Boolean` - defines the buffering mode of
  #   buffers created by the {Rackstash::Sinatra::Middleware} for each request.
  #   You can set it to `:full` to emit only a single log event per request, to
  #   `:data` to accumulate fields and tags on the request's buffer but to emit
  #   a new log event per logged message, or to `:none` to emit log events for
  #   each message and to clear the buffer afterwards. See the Rackstash
  #   documentation of `Rackstash::Buffer#buffering` for details.
  # * `rackstash_request_fields => Hash<#to_s, => Proc, Object>, Fields::Hash, Proc` -
  #   Additional fields to merge into the emitted log event before processing
  #   the request. If the object itself or any of its hash values is a `Proc`,
  #   it will get called, passing the `Rack::Request` object for the current
  #   request as an argument, and its result is used instead.
  # * `rackstash_request_tags => Array<#to_s, Proc>, Set<#to_s, Proc>, Proc` -
  #   an `Array` specifying default tags for each request. You can either give a
  #   literal `Array` containing Strings or a `Proc` which returns such an
  #   `Array`. If the object itself or any of its values is a `Proc`, it is
  #   called, passing the `Rack::Request` object for the current request as an
  #   argument, and its result is used instead.
  # * `rackstash_response_fields => Hash<#to_s, => Proc, Object>, Fields::Hash, Proc` -
  #   Additional fields to merge into the emitted log event after processing the
  #   request and sending the complete response. If the object itself or any of
  #   its hash values is a `Proc`, it will get called, passing the `Hash` of
  #   response headers of the current response as an argument, and its result is
  #   used instead.
  # * `rackstash_response_tags => Array<#to_s, Proc>, Set<#to_s, Proc>, Proc` -
  #   an `Array` specifying default tags for each returned response. You can
  #   either give a literal `Array` containing Strings or a `Proc` which returns
  #   such an `Array`. If the object itself or any of its values is a `Proc`, it
  #   is called, passing the `Hash` of response headers of the current response
  #   as an argument, and its result is used instead.
  #
  # You can set any of these options using Sinatra's `set` method in the class
  # context, e.g.
  #
  #     set :rackstash, "log/#{environment}.log"
  #     set :rackstash_request_fields, {
  #       'user_agent' => ->(request) { request.user_agent },
  #       'remote_ip' => ->(request) { request.ip },
  #       'server' => Socket.gethostname
  #     }
  #
  # In development mode, it is sometimes desirable to produce logs intended for
  # only human consumption, mostly resembling the default logs of Sinatra. To
  # enable that, you configure the Rackstash logger to output only the messages
  # as soon as they are logged. A suitable configuration can look like this:
  #
  #     logger = Rackstash::Logger.new(STDOUT, level: Rackstash::INFO) do |flow|
  #       flow.encoder Rackstash::Encoder::Message.new(['@timestamp'])
  #     end
  #
  #     set :logging, true
  #     set :rackstash, logger
  #     set :rackstash_buffering, :data
  module Sinatra
    # Callback method called by Sinatra when registering this class as a plugin
    # in a Sinatra application. Here, we are setting the default values for
    # the settings described above in the Sinatra application class.
    #
    # @param app [Class] A Sinatra application class
    # @return [void]
    def self.registered(app)
      app.set :rackstash, STDOUT
      app.set :rackstash_buffering, :full

      app.set :rackstash_request_fields, nil
      app.set :rackstash_request_tags, nil
      app.set :rackstash_response_fields, nil
      app.set :rackstash_response_tags, nil

      # Ensure that any Rack::CommonLogger instances are silent if there is a
      # `Rackstash::Sinatra::Middleware` instance in the same middleware stack.
      #
      # This is needed since Rack adds a `Rack::CommonLogger` to the middleware
      # stack in its development and deployment environments which we don't
      # control. Sinatra itself solves this by silencing its "secondary" common
      # logger. Since we want to completely replace Rack's own logger, we have
      # to use slightly more intrusive methods unfortunately.
      Rackstash::Sinatra::SilenceCommonLogger.apply

      # The access logs are disable by default when starting the server via Rack
      # (e.g. with the `rackup` command and a `config.ru` file). When starting
      # the server directly from Sinatra with e.g. `ruby app.rb`, the default
      # options of Rack are not used. We thus have to provide our own sensible
      # defaults to disable the unecessary default access logs of WEBrick in all
      # cases.
      app.set :server_settings, {} unless app.settings.respond_to?(:server_settings)
      app.server_settings[:AccessLog] ||= [] if app.server_settings.respond_to?(:[]=)
    end

    private

    # Setup logging for the Sinatra app. If the {Rackstash::Sinatra} plugin is
    # registered in an application, this method overwrites the class method of
    # the same name in `Sinatra::Base`.
    #
    # If either `logging` is disabled or there is no `rackstash_target`
    # configured, we fallback to Sinatra's default logging behavior. If both
    # settings are enabled / configured, we define a
    # {Rackstash::Sinatra::Middleware} instance in place of the default
    # `::Rack::CommonLogger` middleware for logging and configure a
    # `Rackstash::Logger` with it. Note that all `::Rack::CommonLogger`
    # middlewares in the same middleware stack
    #
    # @param builder [Rack::Builder] A middleware builder
    # @return [void]
    def setup_logging(builder) # :doc:
      return super if rackstash == false

      if logging?
        if rackstash.is_a?(Rackstash::Logger)
          logger = rackstash
        else
          level = logging.respond_to?(:to_int) ? logging.to_int : Rackstash::INFO
          logger = Rackstash::Logger.new(rackstash, level: level)
        end
      else
        logger = Rackstash::Logger.new(nil, level: Rackstash::INFO)
      end

      builder.use(
        Rackstash::Sinatra::Middleware,
        logger,
        buffering: rackstash_buffering,
        request_fields: rackstash_request_fields,
        request_tags: rackstash_request_tags,
        response_fields: rackstash_response_fields,
        response_tags: rackstash_response_tags
      )
    end
  end
end
