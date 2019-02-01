# frozen_string_literal: true

require 'forwardable'

module Trav3
  class Headers
    extend Forwardable
    # @!macro [attach] def_delegators
    #   @!method each_pair
    #     Forwards to $1.
    #     @see Hash#each_pair
    #   @!method fetch
    #     Forwards to $1.
    #     @see Hash#fetch
    def_delegators :@heads, :each_pair, :fetch

    def initialize(args = {})
      build(args)
    end

    # Add or update the request headers
    #
    # @return [Headers] self
    def build(args = {})
      @heads ||= {}

      args.each do |(key, value)|
        @heads[key] = value
      end

      self
    end

    # Remove key/value from headers via key
    #
    # @param key [Symbol, String] key to look up
    # @return [String, Symbol, nil] returns value if key found, `nil` otherwise.
    def remove(key)
      @heads.delete(key)
    end

    # Add the values of one `Headers` into another
    #
    # @param other [Headers] instance of `Headers`
    # @return [Headers]
    def +(other)
      raise TypeError, "Headers type expected, #{other.class} given" unless other.is_a? Headers

      @heads.merge(other.instance_variable_get(:@heads))

      self
    end

    # @return [Hash] hash of the `Headers`
    def to_h
      @heads
    end
  end
end
