# -*- ruby encoding: utf-8 -*-

gem 'minitest'
require 'minitest/autorun'
require 'minitest/pretty_diff'
require 'minitest/focus'
require 'minitest/moar'
require 'minitest/bisect'

require 'stockpile'

class StockpileTestManager
  class Connection
    class << self
      attr_reader :data

      def reset_data
        @data = Hash.new { |h, k| h[k] = {} }
      end
    end

    reset_data

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
      raise unless connected?
      self.class.data[key]
    end

    def set(key, value)
      raise unless connected?
      self.class.data[key] = value
    end

    def hget(key, field)
      raise unless connected?
      self.class.data[key][field]
    end

    def hset(key, field, value)
      raise unless connected?
      self.class.data[key][field] = value
    end
  end

  def initialize(options = {})
    @options    = options.dup
    @narrow     = !!(@options.delete(:narrow) || ::Stockpile.narrow?)
    @connection = nil
    @clients    = {}
  end

  attr_reader :connection

  def narrow?
    @narrow
  end

  def connect(*client_names)
    @connection ||= connect_for_any

    clients_from(*client_names).each { |client_name|
      connection_for(client_name)
    }

    connection
  end

  def connection_for(client_name)
    connect unless connection
    return nil if client_name == :all
    @clients[client_name] ||= connect_for_any
  end

  def reconnect(*client_names)
    return unless connection

    connection.reconnect

    unless narrow?
      clients_from(*client_names).each { |client_name|
        client = @clients[client_name]
        client.reconnect if client
      }
    end

    connection
  end

  def disconnect(*client_names)
    return unless connection

    unless narrow?
      clients_from(*client_names).each { |client_name|
        client = @clients[client_name]
        client.disconnect if client
      }
    end

    connection.disconnect
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
    Connection.new(@options)
  end
end

module Minitest::ENVStub
  def setup
    super
    StockpileTestManager::Connection.reset_data
  end

  def stub_env env, options = {}, *block_args, &block
    mock = lambda { |key|
      env.fetch(key) { |k|
        if options[:passthrough]
          ENV.send(:"__minitest_stub__[]", k)
        else
          nil
        end
      }
    }

    if defined? Minitest::Moar::Stubbing
      stub ENV, :[], mock, *block_args, &block
    else
      ENV.stub :[], mock, *block_args, &block
    end
  end

  Minitest::Test.send(:include, self)
end
