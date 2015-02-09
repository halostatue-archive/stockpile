require 'minitest_config'
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
    let(:cls) { Class.new }
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

        def job_ran(job, value = nil)
          if value
            connection.set(job, !!value)
          else
            !!connection.get(job)
          end
        end
      end
    }

    it "throws an ArgumentError unless it’s a class or module" do
      assert_raises ArgumentError do
        ::Stockpile.inject!(Object.new)
      end
    end

    describe "Stockpile.inject!(Module):" do
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
      before do
        ::Stockpile.inject!(mod, method: :stockpile, adaptable: false)
      end

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
        ::Stockpile.inject!(mod, default_manager: Stockpile::Memory)
      end

      it "queues adaptation until Stockpile has been initialized" do
        stub Stockpile, :new do
          mod.cache_adapter(lrt)
          refute_called Stockpile, :new
          refute_nil mod.instance_variable_get(:@__stockpile_triggers__)
          refute_empty mod.instance_variable_get(:@__stockpile_triggers__)
        end

        assert_equal({ namespace: 'n' },
                     mod.cache(namespace: 'n').connection.options)
        assert_respond_to mod.cache, :last_run_time
        assert_respond_to mod.cache, :job_ran
      end

      it "adapts an initialized Stockpile immediately" do
        mod.cache
        mod.cache_adapter(lrt)
        assert_respond_to mod.cache, :last_run_time
        assert_respond_to mod.cache, :job_ran
        assert_empty mod.instance_variable_get(:@__stockpile_triggers__)
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

      it "adapts the cache with job_ran" do
        mod.cache_adapter(lrt)
        refute mod.cache.job_ran('foo')
        assert mod.cache.job_ran('foo', true)
        assert mod.cache.job_ran('foo')
      end

      it "adapts the module with last_run_time" do
        mod.cache_adapter(lrt, mod)
        refute mod.job_ran('foo')
        assert mod.job_ran('foo', true)
        assert mod.job_ran('foo')
      end

      it "adapts the lrt module with last_run_time" do
        mod.cache_adapter!(lrt)
        refute lrt.job_ran('foo')
        assert lrt.job_ran('foo', true)
        assert lrt.job_ran('foo')
      end
    end

    describe "Stockpile.inject!(Class):" do
      before { ::Stockpile.inject!(cls) }

      it "defines cls.cache" do
        assert_respond_to cls, :cache
      end

      it "defines cls.cache_adapter" do
        assert_respond_to cls, :cache_adapter
      end

      it "defines cls.cache_adapter!" do
        assert_respond_to cls, :cache_adapter!
      end

      it "Fails cache initialization" do
        assert_raises ArgumentError do
          cls.cache
        end
      end
    end
  end
end
