# frozen_string_literal: true

require 'stockpile/base'

class Stockpile
  # An in-memory connection manager, providing a complete example of how a
  # Stockpile connection manager could be made.
  class Memory < Stockpile::Base
    class Data # :nodoc:
      class << self
        attr_reader :data

        def reset
          @data = {}
        end
      end

      reset

      attr_reader :options

      def initialize(options = {})
        @connected = false
        @options   = options
        connect
      end

      def connect
        @connected = true
      end
      alias_method :reconnect, :connect

      def disconnect
        @connected = false
      end

      def connected?
        !!@connected
      end

      def get(key)
        check_valid!
        self.class.data[key]
      end

      def set(key, value)
        check_valid!
        self.class.data[key] = value
      end

      def hget(key, field)
        fail unless connected?
        valid_hkey!(key)[field]
      end

      def hset(key, field, value)
        fail unless connected?
        valid_hkey!(key)[field] = value
      end

      private

      def check_valid!
        fail unless connected?
      end

      def valid_hkey!(key)
        check_valid!
        case h = self.class.data[key]
        when nil
          h = (self.class.data[key] = {})
        when Hash
          nil
        else
          fail
        end
        h
      end
    end

    ##
    # :singleton-method: new
    # :call-seq:
    #   new(options = {})
    #
    # Create a new Memory connection manager.

    ##
    # :attr_reader: connection
    #
    # The primary connection.

    ##
    # :method: narrow?
    #
    # Indicates if this connection manager is using a narrow connection width.

    ##
    # :method: connect
    # :call-seq:
    #   connect(*client_names)
    #
    # Connect unless already connected. Additional client connections can be
    # specified in the parameters as a shorthand for calls to #connection_for.
    #
    # If #narrow? is true, the same connection will be used for all clients
    # managed by this connection manager.
    #
    #   manager.connect
    #   manager.connection_for(:bar)
    #
    #   # This means the same as above.
    #   manager.connect(:bar)

    ##
    # :method: connection_for
    # :call-seq:
    #   connection_for(client_name, options = {})
    #
    # Perform a client connection for a specific +client_name+. A +client_name+
    # of +:all+ will always return +nil+. If the requested client does not yet
    # exist, the connection will be created.

    ##
    # :method: reconnect
    # :call-seq:
    #   reconnect(*client_names)
    #
    # Reconnect some or all clients. The primary connection will always be
    # reconnected; other clients will be reconnected based on the +clients+
    # provided. Only clients actively managed by previous calls to #connect or
    # #connection_for will be reconnected.
    #
    # If #reconnect is called with the value +:all+, all currently managed
    # clients will be reconnected.
    #
    # If #narrow? is true, the primary connection will be reconnected, which
    # reconnects all connections implicitly.

    ##
    # :method: disconnect
    # :call-seq:
    #   disconnect(*client_names)
    #
    # Disconnect for some or all clients. The primary connection will always
    # be disconnected; other clients will be disconnected based on the
    # +clients+ provided. Only clients actively managed by previous calls to
    # #connect or #connection_for will be disconnected.
    #
    # If #disconnect is called with the value +:all+, all currently managed
    # clients will be disconnected.
    #
    # If #narrow? is true, the primary connection will be disconnected,
    # which disconnects all connections implicitly.

    ##

    private

    def client_connect(_name = nil, options = {})
      return connection if connection && narrow?
      Data.new(@options.merge(options))
    end

    def client_reconnect(client = connection)
      client.reconnect if client
    end

    def client_disconnect(client = connection)
      client.disconnect if client
    end
  end
end
