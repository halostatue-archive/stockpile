# -*- ruby encoding: utf-8 -*-

gem 'minitest'
require 'minitest/autorun'
require 'minitest/pretty_diff'
require 'minitest/focus'
require 'minitest/moar'
require 'minitest/rerun'
require 'minitest/bisect'

require 'fakeredis'

require 'stockpile'

module Minitest::ENVStub
  def setup
    super
    Redis::Connection::Memory.reset_all_databases
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
