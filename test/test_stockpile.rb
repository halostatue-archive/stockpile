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

  describe ".inject!" do
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

    describe "Stockpile.inject!(Mod):" do
      before { ::Stockpile.inject!(mod) }

      it "defines Mod.cache" do
        assert_respond_to mod, :cache
      end

      it "defines Mod.cache_adapter" do
        assert_respond_to mod, :cache_adapter
      end

      it "defines Mod.cache_adapter!" do
        assert_respond_to mod, :cache_adapter!
      end

      it "Fails cache initialization" do
        assert_raises ArgumentError do
          mod.cache
        end
      end
    end

    describe "Stockpile.inject!(Mod, adaptable: false)" do
      before { ::Stockpile.inject!(mod, adaptable: false) }

      it "defines Mod.cache" do
        assert_respond_to mod, :cache
      end

      it "does not define Mod.cache_adapter or Mod.cache_adapter!" do
        refute_respond_to mod, :cache_adapter
        refute_respond_to mod, :cache_adapter!
      end
    end

    describe "Stockpile.inject!(Mod, method: stockpile)" do
      before { ::Stockpile.inject!(mod, method: :stockpile) }

      it "defines Mod.stockpile" do
        assert_respond_to mod, :stockpile
      end

      it "defines Mod.stockpile_adapter" do
        assert_respond_to mod, :stockpile_adapter
      end

      it "defines Mod.stockpile_adapter!" do
        assert_respond_to mod, :stockpile_adapter!
      end
    end

    describe "Stockpile.inject!(Mod, method: :stockpile, adaptable: false)" do
      before { ::Stockpile.inject!(mod, method: :stockpile, adaptable: false) }

      it "defines Mod.stockpile" do
        assert_respond_to mod, :stockpile
      end

      it "does not define Mod.stockpile_adapter or Mod.stockpile_adapter!" do
        refute_respond_to mod, :stockpile_adapter
        refute_respond_to mod, :stockpile_adapter!
      end
    end

    describe "Mod.cache_adapter" do
      let(:now) { Time.now }
      let(:iso) { now.utc.iso8601 }
      before do
        ::Stockpile.inject!(mod, adaptable: true,
                            default_manager: StockpileTestManager)
      end

      it "adapts the cache with last_run_time" do
        mod.cache_adapter(lrt)
        assert_nil mod.cache.last_run_time('foo')
        assert_equal iso, mod.cache.last_run_time('foo', now)
        assert_equal now.to_i, mod.cache.last_run_time('foo').to_i
      end

      it "adapts the module with last_run_time" do
        mod.cache_adapter(lrt, mod)
        assert_nil mod.last_run_time('foo')
        assert_equal iso, mod.last_run_time('foo', now)
        assert_equal now.to_i, mod.last_run_time('foo').to_i
      end

      it "adapts the lrt module with last_run_time" do
        mod.cache_adapter!(lrt)
        assert_nil lrt.last_run_time('foo')
        assert_equal iso, lrt.last_run_time('foo', now)
        assert_equal now.to_i, lrt.last_run_time('foo').to_i
      end
    end
  end

  # Testing #connection, #connect, #connection_for, #reconnect, and #disconnect
  # are testing Forwardable. Those tests are to be done in the individual
  # connectors.
end
