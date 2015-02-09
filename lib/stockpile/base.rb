# coding: utf-8

require 'stockpile'

class Stockpile
  # The base connection manager, providing some common functionality for
  # connection managers.
  #
  # It is not necessary to implement a connection manager from Stockpile::Base,
  # but it is recommended because it provides all of the core functionality
  # required of all connection managers, and requires only four integration
  # points:
  #
  # * +initialize+: The constructor for the client connection manager. This
  #   should call +super+ at the beginning of its own implementation, and use
  #   <tt>@options</tt> if further parsing or manipulation of provided options
  #   is required.
  # * +client_connect+: The actions necessary to connect clients.
  # * +client_reconnect+: The actions necessary to reconnect clients.
  # * +client_disconnect+: The actions necessary to disconnect clients.
  class Base
    # Create a new connection manager with the provided options.
    #
    # == Options
    #
    # +narrow+::    Use a narrow connection width if true; if not provided,
    #               uses the value of ::Stockpile.narrow? in this connection
    #               manager.
    def initialize(options = {})
      @options    = options.dup
      @narrow     = !!@options.fetch(:narrow, ::Stockpile.narrow?)
      @connection = nil
      @clients    = {}

      @options.delete(:narrow)
    end

    # The primary connection.
    attr_reader :connection

    # Indicates if this connection manager is using a narrow connection width.
    def narrow?
      @narrow
    end

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
    def connect(*client_names)
      @connection ||= client_connect

      clients_from(*client_names).each { |name, options|
        connection_for(name, options || {})
      }

      connection
    end

    # Perform a client connection for a specific +client_name+. A +client_name+
    # of +:all+ will always return +nil+. If the requested client does not yet
    # exist, the connection will be created.
    def connection_for(client_name, options = {})
      connect unless connection
      return nil if client_name == :all

      @clients[client_name] ||= client_connect(client_name, options)
    end

    # Reconnect some or all clients. The primary connection will always be
    # reconnected; other clients will be reconnected based on the +clients+
    # provided. Only clients actively managed by previous calls to #connect
    # or #connection_for will be reconnected.
    #
    # If #reconnect is called with the value +:all+, all currently managed
    # clients will be reconnected.
    #
    # If #narrow? is true, the primary connection will be reconnected, which
    # reconnects all connections implicitly.
    def reconnect(*client_names)
      return unless connection

      client_reconnect

      unless narrow?
        clients_from(*client_names).each { |client_name, _|
          client_reconnect(@clients[client_name])
        }
      end

      connection
    end

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
    def disconnect(*client_names)
      return unless connection

      unless narrow?
        clients_from(*client_names).each { |client_name, _|
          client_disconnect(@clients[client_name])
        }
      end

      client_disconnect
    end

    private
    # Converts +client_names+ into a hash of client names to options.
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
    def clients_from(*client_names)
      clients = if client_names.size == 1
                  if client_names.first == :all
                    @clients.keys
                  else
                    client_names
                  end
                else
                  client_names
                end
      clients.map { |v|
        case v
        when Hash
          v
        else
          { v => {} }
        end
      }.inject({}, :merge)
    end

    # Performs a client connect action. Must be implemented by a client.
    def client_connect(name = nil, options = {})
      raise NotImplementedError
    end

    # Performs a client reconnect action. Must be implemented by a client.
    def client_reconnect(client = connect())
      raise NotImplementedError
    end

    # Performs a client disconnect action. Must be implemented by a client.
    def client_disconnect(client = connect())
      raise NotImplementedError
    end
  end
end
