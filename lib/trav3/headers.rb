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

      args.each do |(key, value)|
        @heads[key] = value
      end

      self
    end

    def remove(key)
      @heads.delete(key)
    end

    def +(other)
      raise TypeError, "Headers type expected, #{other.class} given" unless other.is_a? Headers

      @heads.merge(other.instance_variable_get(:@heads))

      self
    end

    def to_h
      @heads
    end
  end
end
