require 'minitest_config'
require 'stockpile'
require 'time'

describe Stockpile do
  describe ".narrow?" do
    it "is wide by default" do
      stub_env({}) do
        refute Stockpile.narrow?
      end
    end

    it "is narrow when $STOCKPILE_CONNECTION_WIDTH = 'narrow'" do
      stub_env({ 'STOCKPILE_CONNECTION_WIDTH' => 'narrow' }) do
        assert Stockpile.narrow?
      end
    end
  end

  describe ".enable!" do
    let(:mod) { Module.new }
    let(:lrt) {
      Module.new do
        def last_run_time(key, value = nil)
          if value
            connection.hset(__method__, key, value.utc.iso8601)
          else
            value = connection.hget(__method__, key)
            Time.parse(value) if value
          end
        end
      end
    }

    it "provides Mod.cache" do
      ::Stockpile.enable!(mod)
      assert_respond_to mod, :cache
      assert_equal "OK", mod.cache.connection.set('answer', 42)
      assert_equal "42", mod.cache.connection.get('answer')
    end

    it "{ adaptable: true } -> Mod.cache_adapter[!]" do
      ::Stockpile.enable!(mod, :adaptable => true)
      assert_respond_to mod, :cache_adapter
      assert_respond_to mod, :cache_adapter!
    end

    it "{ method: stockpile } -> Mod.stockpile" do
      ::Stockpile.enable!(mod, :method => :stockpile)
      assert_respond_to mod, :stockpile
    end

    it "{ method: :stockpile, adaptable: true } -> Mod.stockpile_adapter[!]" do
      ::Stockpile.enable!(mod, :method => :stockpile, :adaptable => true)
      assert_respond_to mod, :stockpile_adapter
      assert_respond_to mod, :stockpile_adapter!
    end

    describe "Mod.cache_adapter" do
      let(:now) { Time.now }
      before { ::Stockpile.enable!(mod, :adaptable => true) }

      it "adapts the cache with last_run_time" do
        mod.cache_adapter(lrt)
        assert_nil mod.cache.last_run_time('foo')
        assert_equal true, mod.cache.last_run_time('foo', now)
        assert_equal now.to_i, mod.cache.last_run_time('foo').to_i
      end

      it "adapts the module with last_run_time" do
        mod.cache_adapter(lrt, mod)
        assert_nil mod.last_run_time('foo')
        assert_equal true, mod.last_run_time('foo', now)
        assert_equal now.to_i, mod.last_run_time('foo').to_i
      end

      it "adapts the lrt module with last_run_time" do
        mod.cache_adapter!(lrt)
        assert_nil lrt.last_run_time('foo')
        assert_equal true, lrt.last_run_time('foo', now)
        assert_equal now.to_i, lrt.last_run_time('foo').to_i
      end
    end
  end

  describe ".default_connection_manager" do
    it "defaults to Stockpile::RedisConnectionManager" do
      assert_same Stockpile::RedisConnectionManager,
        ::Stockpile.default_connection_manager
    end

    it "can be set to something else" do
      ::Stockpile.default_connection_manager = Object
      assert_same Object, ::Stockpile.default_connection_manager
      ::Stockpile.default_connection_manager =
        ::Stockpile::RedisConnectionManager
    end
  end

  # Testing #connection, #connect, #connection_for, #reconnect, and #disconnect
  # are testing Forwardable. Those tests are to be done in the individual
  # connectors.
end
