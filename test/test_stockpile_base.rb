# frozen_string_literal: true
require 'minitest_config'

describe Stockpile::Base do
  def assert_clients expected_clients, connector
    actual_clients = connector.instance_variable_get(:@clients).keys
    assert_equal actual_clients.sort, expected_clients.sort
  end

  let(:mem) {
    stub_env({}) { Stockpile::Memory.new }
  }
  let(:mem_namespace) {
    stub_env({}) { Stockpile::Memory.new(namespace: 'Z') }
  }
  let(:mem_wide) {
    stub_env({}) { Stockpile::Memory.new(narrow: false) }
  }
  let(:mem_narrow) {
    stub_env({}) { Stockpile::Memory.new(narrow: true) }
  }

  describe 'constructor' do
    it 'uses the default connection width by default' do
      stub ::Stockpile, :narrow?, lambda { false } do
        refute Stockpile::Base.new.narrow?, 'should be narrow, but is not'
      end

      stub ::Stockpile, :narrow?, lambda { true } do
        assert Stockpile::Base.new.narrow?, 'is not narrow, but should be'
      end
    end

    it 'can be told which connection width to use explicitly' do
      stub ::Stockpile, :narrow?, lambda { false } do
        assert mem_narrow.narrow?
      end

      stub ::Stockpile, :narrow?, lambda { true } do
        refute mem_wide.narrow?
      end
    end

    it 'passes settings through to the client' do
      options = {
        url: 'test://xyz/'
      }
      mem = ::Stockpile::Memory.new(options)
      assert_equal 'test://xyz/', mem.connect.options[:url]
    end

    it 'has no clients by default' do
      assert_clients [], ::Stockpile::Memory.new
    end

    it 'works with an OpenStruct provided as options' do
      require 'ostruct'
      mem = ::Stockpile::Memory.new(OpenStruct.new(url: 'test://xyz/'))
      assert_equal 'test://xyz/', mem.connect.options[:url]
    end
  end

  describe '#connect' do
    it 'raises NotImplementedError unless #client_connect is implemented' do
      assert_raises NotImplementedError do
        ::Stockpile::Base.new.connect
      end
    end

    it 'creates a connection to the client' do
      assert_nil mem.connection
      refute_nil mem.connect
    end

    it 'creates a namespaced connection to the client' do
      assert_nil mem_namespace.connection
      refute_nil mem_namespace.connect
    end

    describe 'with a wide connection width' do
      before do
        mem_wide.connect(:hoge, quux: {})
      end

      it 'connects multiple clients' do
        assert_clients [ :hoge, :quux ], mem_wide
      end

      it 'connects *different* clients' do
        refute_same mem_wide.connection, mem_wide.connection_for(:hoge)
        refute_same mem_wide.connection, mem_wide.connection_for(:quux)
        refute_same mem_wide.connection_for(:hoge), mem_wide.connection_for(:quux)
      end
    end

    describe 'with a narrow connection width' do
      before do
        mem_narrow.connect(:hoge, :quux)
      end

      it 'appears to connect multiple clients' do
        assert_clients [ :hoge, :quux ], mem_narrow
      end

      it 'returns identical clients' do
        assert_same mem_narrow.connection, mem_narrow.connection_for(:hoge)
        assert_same mem_narrow.connection, mem_narrow.connection_for(:quux)
        assert_same mem_narrow.connection_for(:hoge), mem_narrow.connection_for(:quux)
      end
    end
  end

  describe '#connection_for' do
    it 'raises NotImplementedError unless #client_connect is implemented' do
      assert_raises NotImplementedError do
        instance_stub ::Stockpile::Base, :connection, -> { true } do
          ::Stockpile::Base.new.connection_for(:foo)
        end
      end
    end

    describe 'with a wide connection width' do
      it 'connects the main client' do
        mem_wide.connection_for(:global)
        assert mem_wide.connection
        refute_same mem_wide.connection, mem_wide.connection_for(:global)
      end
    end

    describe 'with a narrow connection width' do
      it 'connects the main client' do
        mem_narrow.connection_for(:global)
        assert mem_narrow.connection
        assert_same mem_narrow.connection, mem_narrow.connection_for(:global)
      end
    end
  end

  let(:connection) { Stockpile::Memory::Data }

  describe '#disconnect' do
    it 'raises NotImplementedError unless #client_disconnect is implemented' do
      base = ::Stockpile::Base.new
      assert_raises NotImplementedError do
        instance_stub ::Stockpile::Base, :connect do
          instance_stub ::Stockpile::Base, :connection, -> { true } do
            base.disconnect
          end
        end
      end
    end

    describe 'with a wide connection width' do
      let(:global) { mem_wide.connection }
      let(:hoge) { mem_wide.connection_for(:hoge) }

      before do
        mem_wide.connect(:hoge)
        assert hoge.connected? && global.connected?
      end

      it 'disconnects the global client' do
        mem_wide.disconnect
        assert hoge.connected? && !global.connected?
      end

      it 'disconnects the redis and global clients' do
        mem_wide.disconnect(:hoge)
        refute hoge.connected? || global.connected?
      end
    end

    describe 'with a narrow connection width' do
      let(:global) { mem_narrow.connection }
      let(:hoge) { mem_narrow.connection_for(:hoge) }

      before do
        mem_narrow.connect(:hoge)
        assert hoge.connected? && global.connected?
      end

      it '#disconnect disconnects all clients' do
        mem_narrow.disconnect
        refute hoge.connected? || global.connected?
      end

      it '#disconnect(:hoge) disconnects all clients' do
        mem_narrow.disconnect(:hoge)
        refute hoge.connected? || global.connected?
      end
    end
  end

  describe '#reconnect' do
    it 'raises NotImplementedError unless #client_reconnect is implemented' do
      base = ::Stockpile::Base.new
      assert_raises NotImplementedError do
        instance_stub ::Stockpile::Base, :connect do
          instance_stub ::Stockpile::Base, :connection, -> { true } do
            base.reconnect
          end
        end
      end
    end

    describe 'with a wide connection width' do
      let(:global) { mem_wide.connection }
      let(:hoge) { mem_wide.connection_for(:hoge) }

      before do
        mem_wide.connect(:hoge)
        assert hoge.connected? && global.connected?
        mem_wide.disconnect(:all)
        refute hoge.connected? || global.connected?
      end

      it 'reconnects the global client' do
        mem_wide.reconnect
        assert !hoge.connected? && global.connected?
      end

      it 'reconnects the redis and global clients' do
        mem_wide.reconnect(:hoge)
        assert hoge.connected? && global.connected?
      end
    end

    describe 'with a narrow connection width' do
      let(:global) { mem_narrow.connection }
      let(:hoge) { mem_narrow.connection_for(:hoge) }

      def force_connection
        mem_narrow.connect(:hoge)
        assert hoge.connected? && global.connected?
        mem_wide.disconnect(:all)
        refute hoge.connected? || global.connected?
      end

      it '#reconnect reconnects the all clients' do
        mem_narrow.reconnect
        assert hoge.connected? && global.connected?
      end

      it '#reconnect(:hoge:) reconnects all clients' do
        mem_narrow.reconnect(:hoge)
        assert hoge.connected? && global.connected?
      end
    end
  end
end
