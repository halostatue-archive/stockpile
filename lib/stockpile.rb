# coding: utf-8

require 'forwardable'

# Stockpile is a thin wrapper around connections to a fast key-value store
# used for caching (currently only supporting Redis).
#
# This provides a couple of layers of functionality:
#
# * Connection management. Some third-party providers of Redis limit
#   simultaneous connections; Stockpile can manage a single connection that
#   gets shared by all clients using a Stockpile instance.
# * Providing an application-level cache adapter mechanism.
class Stockpile
  extend Forwardable

  VERSION = "1.1" # :nodoc:

  @default_manager = nil

  class << self
    # Determines if the default connection width is narrow or wide based on
    # the environment variable STOCKPILE_CONNECTION_WIDTH.
    def narrow?
      (ENV['STOCKPILE_CONNECTION_WIDTH'] == 'narrow')
    end

    # Enables module or class +mod+ to contain a Stockpile instance and
    # provide an adapter interface (this can be disabled). This creates a
    # singleton method that returns a singleton Stockpile instance.
    #
    # === Options
    # +method+:: The name of the method that manages the Stockpile instance.
    #            Defaults to +cache+.
    # +adaptable+:: Defines an adapter method if truthy (the default). Pass a
    #               falsy value to disable. (The created adapter method will be
    #               named according to the value of +method+, and so defaults
    #               to +cache_adapter+.
    #
    # === Synopsis
    #
    #   # Using only for connection management.
    #   module Application
    #     Stockpile.inject!(self, adaptable: false)
    #   end
    #   Application.cache # => a stockpile instance
    #   Application.cache.connection.set('answer', 42)
    #   Application.cache.connection.get('answer')
    #
    #   module LastRunTime
    #     def last_run_time(key, value = nil)
    #       if value
    #         connection.hset(__method__, key, value.utc.iso8601)
    #       else
    #         value = connection.hget(__method__, key)
    #         Time.parse(value) if value
    #       end
    #     end
    #   end
    #
    #   module AdaptableApplication; end
    #   Stockpile.inject!(AdaptableApplication)
    #
    #   # Adapt the cache object to recognize #last_run_time;
    #   AdaptableApplication.cache_adapter(LastRunTime)
    #   AdaptableApplication.cache.last_run_time('adaptable_application')
    #
    #   # or adapt AdaptableApplication to recognize #last_run_time;
    #   AdaptableApplication.cache_adapter(LastRunTime,
    #                                      AdaptableApplication)
    #   AdaptableApplication.last_run_time('adaptable_application')
    #
    #   # or adapt LastRunTime to recognize #last_run_time.
    #   AdaptableApplication.cache_adapter!(LastRunTime)
    #   LastRunTime.last_run_time('adaptable_application')
    def inject!(mod, options = {})
      unless mod.kind_of?(Module)
        raise ArgumentError, "#{mod} is not a class or module"
      end

      name    = options.fetch(:method, :cache).to_sym
      mklass  = mod.singleton_class
      default = options.fetch(:default_manager, nil)

      mklass.send(:define_method, name) do |init_options = {}|
        init_options = init_options.merge(default_manager: default)
        @__stockpile__ ||= ::Stockpile.new(init_options)
        @__stockpile_triggers__ ||= []

        triggers, @__stockpile_triggers__ = @__stockpile_triggers__, []
        triggers.each(&:call)

        @__stockpile__
      end

      if options.fetch(:adaptable, true)
        adapter = :"#{name}_adapter"
        mklass.send(:define_method, adapter) do |m, k = nil|
          o = self

          @__stockpile_triggers__ ||= []

          trigger = -> { send(name).singleton_class.send(:include, m) }

          if defined?(@__stockpile__) && @__stockpile__
            trigger.call
          else
            @__stockpile_triggers__ << trigger
          end

          if k
            mk = k.singleton_class
            m.public_instance_methods.each do |pim|
              mk.send(:define_method, pim) do |*args, &block|
                o.send(name).send(pim, *args, &block)
              end
            end
          end
        end

        mklass.send(:define_method, :"#{adapter}!") do |m|
          send(adapter, m, m)
        end
      end
    end

    # The default Stockpile cache connection manager.
    attr_accessor :default_manager
  end

  # Creates a new Stockpile instance and connects to the connection provider
  # using the provided options and block.
  #
  # === Options
  #
  # The options hash contains configuration for the Stockpile and its
  # connection manager. The following options are handled specially by the
  # Stockpile constructor and not made available to the connection provider
  # constructor.
  #
  # +manager+:: The connection manager that will be used for creating
  #             connections to this Stockpile. If not provided, either
  #             +default_manager+ or ::Stockpile.default_manager will be used.
  #             An error will be raised if no connection provider is available
  #             through any means.
  # +clients+:: Connections will be created for the provided list of clients.
  #             These connections must be assigned to their appropriate clients
  #             after initialization. This may also be called +client+. These
  #             values may be provided as names (e.g., +:cache+), or as hashes
  #             of client name to client options (e.g., <tt>{ cache: {
  #             namespace: 'x' } }</tt>). See Stockpile#connect for more
  #             details on this latter format.
  #
  # All other options will be passed to the connection provider.
  #
  # === Synopsis
  #
  #   # Create and assign a connection to Redis.current, Resque, and Rollout.
  #   # Under a narrow connection management width, all three will be the
  #   # same client connection.
  #   options = {
  #     manager: Stockpile::Redis,
  #     clients: [ :redis, :resque ]
  #   }
  #   Stockpile.new(options) do |stockpile|
  #    Redis.current = stockpile.connection_for(:redis)
  #    Resque.redis = stockpile.connection_for(:resque)
  #    # Clients will be created by name if necessary.
  #    $rollout = Rollout.new(stockpile.connection_for(:rollout))
  #  end
  def initialize(options = {})
    options = options.dup
    manager = options.delete(:manager)
    default = options.delete(:default_manager) || self.class.default_manager

    unless manager || default
      raise ArgumentError, "No connection manager provided or set as default."
    end

    manager ||= default

    clients = [
      Array(options.delete(:clients)), Array(options.delete(:client))
    ].flatten.uniq

    @manager = manager.new({ narrow: Stockpile.narrow? }.merge(options))

    connect(*clients)
    yield self if block_given?
  end

  ##
  # :attr_reader: connection
  #
  # The currently active connection to the cache provider.
  def_delegator :@manager, :connection

  ##
  # :method: connect
  # :call-seq:
  #   connect
  #   connect(*clients)
  #
  # This will connect the Stockpile instance to the cache provider, optionally
  # including for a set of named clients.
  #
  # If the connection is using a narrow connection width, the same connection
  # will be shared.
  #
  # === Clients
  #
  # +clients+ may be provided in one of several ways:
  #
  # * A Hash object, mapping client names to client options.
  #
  #     connect(redis: nil, rollout: { namespace: 'rollout' })
  #     # Transforms into:
  #     # connect(redis: {}, rollout: { namespace: 'rollout' })
  #
  # * An (implicit) array of client names, for connections with no options
  #   provided.
  #
  #     connect(:redis, :resque, :rollout)
  #     # Transforms into:
  #     # connect(redis: {}, resque: {}, rollout: {})
  #
  # * An array of Hash objects, mapping client names to client options.
  #
  #     connect({ redis: nil },
  #             { rollout: { namespace: 'rollout' } })
  #     # Transforms into:
  #     # connect(redis: {}, rollout: { namespace: 'rollout' })
  #
  # * A mix of client names and Hash objects:
  #
  #     connect(:redis, { rollout: { namespace: 'rollout' } })
  #     # Transforms into:
  #     # connect(redis: {}, rollout: { namespace: 'rollout' })
  #
  # ==== Client Options
  #
  # Stockpile cache providers will handle the parsing of options to ensure that
  # only suitable options are passed along (most providers will ignore any
  # options that change the target system).
  def_delegator :@manager, :connect

  ##
  # :method: connection_for
  # :call-seq:
  #   connection_for(client_name)
  #   connection_for(client_name, options)
  #
  # Returns a connection for a particular client. If the connection manager is
  # using a narrow connection width, this returns the same as #connection.
  #
  # The +client_name+ of +:all+ will always return +nil+.
  #
  # If the requested client does not yet exist, the connection will be created
  # with the provided options.
  def_delegator :@manager, :connection_for

  ##
  # :method: reconnect
  # :call-seq:
  #   reconnect
  #   reconnect(:all)
  #   reconnect(*clients)
  #
  # This will reconnect one or more clients.
  def_delegator :@manager, :reconnect

  ##
  # :method: disconnect
  # :call-seq:
  #   disconnect
  #   disconnect(:all)
  #   disconnect(*clients)
  #
  # This will disconnect one or more clients.
  def_delegator :@manager, :disconnect
end
