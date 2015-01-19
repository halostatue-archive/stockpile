# coding: utf-8

class Stockpile
  # A connection manager for Redis.
  class RedisConnectionManager
    # Create a new Redis connection manager with the provided options.
    #
    # == Options
    #
    # +redis+::     Provides the Redis connection options.
    # +namespace+:: Provides the Redis namespace to use, but only if
    #               redis-namespace is in use (detected with the existence of
    #               Redis::Namespace).
    #
    #               The namespace can also be provided as a key in the +redis+
    #               options if it is missing from the main options. If there is
    #               no namespace key present in either +options+ or
    #               <tt>options[:redis]</tt>, a namespace will be generated
    #               from one of the following: <tt>$REDIS_NAMESPACE</tt>,
    #               <tt>Rails.env</tt> (if in Rails), or <tt>$RACK_ENV</tt>.
    # +narrow+::    Use a narrow connection width if true; if not provided,
    #               uses the value of ::Stockpile.narrow? in this connection
    #               manager.
    def initialize(options = {})
      @redis_options = options.fetch(:redis, {})
      @narrow        = !!options.fetch(:narrow, ::Stockpile.narrow?)
      @namespace     = options.fetch(:namespace) {
        @redis_options.fetch(:namespace) {
          ENV['REDIS_NAMESPACE'] ||
          (defined?(Rails) && Rails.env) ||
          ENV['RACK_ENV']
        }
      }

      if @redis_options.has_key?(:namespace)
        @redis_options = @redis_options.reject { |k, _| k == :namespace }
      end

      @connection = nil
      @clients    = {}
    end

    # The current primary connection to Redis.
    attr_reader :connection

    # Indicates if this connection manager is using a narrow connection
    # width.
    def narrow?
      @narrow
    end

    # Connect to Redis, unless already connected. Additional client connections
    # can be specified in the parameters as a shorthand for calls to
    # #connection_for.
    #
    # If #narrow? is true, the same Redis connection will be used for all
    # clients managed by this connection manager.
    #
    #   manager.connect
    #   manager.connection_for(:redis)
    #
    #   # This means the same as above.
    #   manager.connect(:redis)
    def connect(*client_names)
      @connection ||= connect_for_any

      clients_from(*client_names).each { |client_name|
        connection_for(client_name)
      }

      connection
    end

    # Perform a client connection to Redis for a specific +client_name+. The
    # +client_name+ of +:all+ will always return +nil+.
    #
    # If the requested client does not yet exist, the connection will be
    # created.
    #
    # Because Resque depends on Redis::Namespace, #connection_for will perform
    # special Redis::Namespace handling for a connection with the name
    # +:resque+.
    #
    # If #narrow? is true, the same Redis connection will be shared between all
    # clients.
    #
    # If a connection has not yet been made, it will be made.
    def connection_for(client_name)
      connect unless connection
      return nil if client_name == :all
      @clients[client_name] ||= case client_name
                                when :resque
                                  connect_for_resque
                                else
                                  connect_for_any
                                end
    end

    # Reconnect to Redis for some or all clients. The primary connection will
    # always be reconnected; other clients will be reconnected based on the
    # +clients+ provided. Only clients actively managed by previous calls to
    # #connect or #connection_for will be reconnected.
    #
    # If #reconnect is called with the value +:all+, all currently managed
    # clients will be reconnected.
    #
    # If #narrow? is true, only the primary connection will be reconnected.
    def reconnect(*client_names)
      return unless connection

      connection.client.reconnect

      unless narrow?
        clients_from(*client_names).each { |client_name|
          redis = @clients[client_name]
          redis.client.reconnect if redis
        }
      end

      connection
    end

    # Disconnect from Redis for some or all clients. The primary connection
    # will always be disconnected; other clients will be disconnected based on
    # the +clients+ provided. Only clients actively managed by previous calls
    # to #connect or #connection_for will be disconnected.
    #
    # If #disconnect is called with the value +:all+, all currently managed
    # clients will be disconnected.
    #
    # If #narrow? is true, only the primary connection will be disconnected.
    def disconnect(*client_names)
      return unless connection

      unless narrow?
        clients_from(*client_names).each { |client_name|
          redis = @clients[client_name]
          redis.quit if redis
        }
      end

      connection.quit
    end

    private
    def clients_from(*client_names)
      if client_names.size == 1
        if client_names.first == :all
          @clients.keys
        else
          client_names
        end
      else
        client_names
      end
    end

    def connect_for_any
      return connection if connection && narrow?

      r = Redis.new(@redis_options)
      if @namespace && defined? Redis::Namespace
        r = Redis::Namespace.new(@namespace, redis: r)
      end
      r
    end

    def connect_for_resque
      r = connect_for_any

      if r.instance_of?(Redis::Namespace) && r.namespace.to_s !~ /:resque\z/
        r = Redis::Namespace.new(:"#{r.namespace}:resque", redis: r.redis)
      elsif r.instance_of?(Redis)
        r = Redis::Namespace.new("resque", redis: r)
      end

      r
    end
  end
end
