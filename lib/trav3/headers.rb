require 'forwardable'

module Trav3
  class Headers
    extend Forwardable
    def_delegators :@heads, :each_pair

    def initialize(**args)
      build(**args)
    end

    def build(**args)
      @heads ||= {}

      for (key, value) in args
        @heads[key] = value
      end
    end

    def remove(key)
      @heads.delete(key)
    end

    def +(other)
      raise ArgumentError, "Invalid type provided." unless other.is_a?(Headers)
      @heads.merge(other.instance_variable_get(:@heads))
    end

    def to_h
      @heads
    end
  end
end
