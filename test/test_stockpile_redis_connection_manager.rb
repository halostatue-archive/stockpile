require 'minitest_config'
require 'redis-namespace'
require 'stockpile'

describe Stockpile::RedisConnectionManager do
  def assert_clients expected_clients, connector
    actual_clients = connector.instance_variable_get(:@clients).keys
    assert_equal actual_clients.sort, expected_clients.sort
  end

  let(:rcm) { Stockpile::RedisConnectionManager.new }
  let(:rcm_namespace) { Stockpile::RedisConnectionManager.new(namespace: 'Z') }
  let(:rcm_wide) { Stockpile::RedisConnectionManager.new(narrow: false) }
  let(:rcm_narrow) { Stockpile::RedisConnectionManager.new(narrow: true) }

  describe 'constructor' do
    it "uses the default connection width by default" do
      stub ::Stockpile, :narrow?, lambda { false } do
        refute Stockpile::RedisConnectionManager.new.narrow?,
          "should be narrow, but is not"
      end

      stub ::Stockpile, :narrow?, lambda { true } do
        assert Stockpile::RedisConnectionManager.new.narrow?,
          "is not narrow, but should be"
      end
    end

    it "can be told which connection width to use explicitly" do
      stub ::Stockpile, :narrow?, lambda { false } do
        assert rcm_narrow.narrow?
      end

      stub ::Stockpile, :narrow?, lambda { true } do
        refute rcm_wide.narrow?
      end
    end

    it "passes settings through to Redis" do
      options = {
        redis: {
          url: 'redis://xyz/'
        }
      }
      rcm = ::Stockpile::RedisConnectionManager.new(options)
      assert_equal 'xyz', rcm.connect.client.options[:host]
    end

    it "has no clients by default" do
      assert_clients [], ::Stockpile::RedisConnectionManager.new
    end
  end

  describe "#connect" do
    it "creates a connection to Redis" do
      assert_nil rcm.connection
      refute_nil rcm.connect
      assert_kind_of ::Redis, rcm.connection
    end

    it "creates a namespaced connection to Redis" do
      assert_nil rcm_namespace.connection
      refute_nil rcm_namespace.connect
      assert_kind_of ::Redis::Namespace, rcm_namespace.connection
    end

    describe "with a wide connection width" do
      before do
        rcm_wide.connect(:redis, :rollout)
      end

      it "connects multiple clients" do
        assert_clients [ :redis, :rollout ], rcm_wide
      end

      it "connects *different* clients" do
        refute_same rcm_wide.connection, rcm_wide.connection_for(:redis)
        refute_same rcm_wide.connection, rcm_wide.connection_for(:rollout)
        refute_same rcm_wide.connection_for(:redis), rcm_wide.connection_for(:rollout)
      end
    end

    describe "with a narrow connection width" do
      before do
        rcm_narrow.connect(:redis, :rollout)
      end

      it "appears to connect multiple clients" do
        assert_clients [ :redis, :rollout ], rcm_narrow
      end

      it "returns identical clients" do
        assert_same rcm_narrow.connection, rcm_narrow.connection_for(:redis)
        assert_same rcm_narrow.connection, rcm_narrow.connection_for(:rollout)
        assert_same rcm_narrow.connection_for(:redis), rcm_narrow.connection_for(:rollout)
      end
    end
  end

  describe "#connection_for" do
    describe "with a wide connection width" do
      it "connects the main client" do
        rcm_wide.connection_for(:global)
        assert rcm_wide.connection
        refute_same rcm_wide.connection, rcm_wide.connection_for(:global)
      end

      it "wraps a :resque client in Redis::Namespace" do
        assert_kind_of Redis::Namespace, rcm_wide.connection_for(:resque)
        assert_equal "resque", rcm_wide.connection_for(:resque).namespace
      end
    end

    describe "with a narrow connection width" do
      it "connects the main client" do
        rcm_narrow.connection_for(:global)
        assert rcm_narrow.connection
        assert_same rcm_narrow.connection, rcm_narrow.connection_for(:global)
      end

      it "wraps a :resque client in Redis::Namespace" do
        assert_kind_of Redis::Namespace, rcm_narrow.connection_for(:resque)
      end
    end
  end

  # #disconnect cannot be tested with FakeRedis because the FakeRedis
  # #connected? method always returns true.
  describe "#disconnect" do
    describe "with a wide connection width" do
      let(:global) { rcm_wide.connection }
      let(:redis) { rcm_wide.connection_for(:redis) }

      def force_connection
        rcm_wide.connect(:redis)
        global.client.connect
        redis.client.connect
      end

      it "disconnects the global client" do
        instance_stub Redis, :quit do
          force_connection
          rcm_wide.disconnect
        end
        assert_instance_called Redis, :quit, 1
      end

      it "disconnects the redis and global clients" do
        instance_stub Redis, :quit do
          force_connection
          rcm_wide.disconnect(:redis)
        end
        assert_instance_called Redis, :quit, 2
      end
    end

    describe "with a narrow connection width" do
      let(:global) { rcm_narrow.connection }
      let(:redis) { rcm_narrow.connection_for(:redis) }

      def force_connection
        rcm_narrow.connect(:redis)
        global.client.connect
        redis.client.connect
      end

      it "disconnects the global client" do
        instance_stub Redis, :quit do
          force_connection
          rcm_narrow.disconnect
        end
        assert_instance_called Redis, :quit, 1
      end

      it "disconnects the redis and global clients" do
        instance_stub Redis, :quit do
          force_connection
          rcm_narrow.disconnect(:redis)
        end
        assert_instance_called Redis, :quit, 1
      end
    end
  end

  # #reconnect cannot be tested with FakeRedis because the FakeRedis
  # #connected? method always returns true.
  describe "#reconnect" do
    describe "with a wide connection width" do
      let(:global) { rcm_wide.connection }
      let(:redis) { rcm_wide.connection_for(:redis) }

      def force_connection
        rcm_wide.connect(:redis)
        global.client.connect
        redis.client.connect
      end

      it "reconnects the global client" do
        instance_stub Redis::Client, :reconnect do
          force_connection
          rcm_wide.reconnect
        end
        assert_instance_called Redis::Client, :reconnect, 1
      end

      it "reconnects the redis and global clients" do
        instance_stub Redis::Client, :reconnect do
          force_connection
          rcm_wide.reconnect(:redis)
        end
        assert_instance_called Redis::Client, :reconnect, 2
      end
    end

    describe "with a narrow connection width" do
      let(:global) { rcm_narrow.connection }
      let(:redis) { rcm_narrow.connection_for(:redis) }

      def force_connection
        rcm_narrow.connect(:redis)
        global.client.connect
        redis.client.connect
      end

      it "reconnects the global client" do
        instance_stub Redis::Client, :reconnect do
          force_connection
          rcm_narrow.reconnect
        end
        assert_instance_called Redis::Client, :reconnect, 1
      end

      it "reconnects the redis and global clients" do
        instance_stub Redis::Client, :reconnect do
          force_connection
          rcm_narrow.reconnect(:redis)
        end
        assert_instance_called Redis::Client, :reconnect, 1
      end
    end
  end
end
