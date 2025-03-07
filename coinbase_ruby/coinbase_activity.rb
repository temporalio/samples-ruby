require 'temporal-ruby'

module CoinbaseRuby
  class CoinbaseActivity < Temporal::Activity
    def execute(name)
      "Hello from Coinbase Ruby SDK, #{name}!"
    end
  end
end
