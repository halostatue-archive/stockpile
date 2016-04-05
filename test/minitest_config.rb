# frozen_string_literal: true

gem 'minitest'
require 'minitest/autorun'
require 'minitest/pretty_diff'
require 'minitest/focus'
require 'minitest/moar'
require 'minitest/bisect'

require 'stockpile/memory'

module Minitest::ENVStub
  def setup
    super
    Stockpile::Memory::Data.reset
  end

  def stub_env env, options = {}, *block_args, &block
    mock = lambda { |key|
      env.fetch(key) { |k|
        ENV.send(:"__minitest_stub__[]", k) if options[:passthrough]
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
