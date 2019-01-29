# frozen_string_literal: true

module Trav3
  class Options
    def initialize(args = {})
      build(args)
    end

    # url safe rendering of options for the url
    #
    # @return [String] url options
    def opts
      if @opts.empty?
        ''
      else
        "?#{@opts.join('&')}"
      end
    end

    # Add or update url options
    #
    # @return [Options] self
    def build(args = {})
      @opts ||= []

      args.each do |(key, value)|
        remove(key)
        @opts.push("#{key}=#{value}")
      end

      self
    end

    # Fetch the `key=value`
    #
    # @param [Symbol, String] key of the key/value pair to fetch
    # @return [String] 
    def fetch(key)
      @opts.each do |item|
        return item if key.to_s == split.call(item).first
      end

      raise KeyError, "key not found #{key}" unless block_given?

      yield
    end

    # Fetch and remove `key=value`.  Modifies `Options`.
    #
    # @param [Symbol, String] key of the key/value pair to fetch
    # @return [String] 
    def fetch!(key, &block)
      result = fetch(key, &block)
      remove(key)
      result
    end

    # Execute a block of code and restore original `Options` state afterwards
    # @yield [Options]
    def immutable
      old = @opts
      result = yield self
      @opts = old
      result
    end

    # Remove key/value from options via key
    #
    # @param key [Symbol, String] key to look up
    # @return [String, nil] returns a `String` if key found, `nil` otherwise.
    def remove(key)
      return_value = nil

      @opts = @opts.delete_if do |item|
        head, tail = split.call item

        return_value = tail if head == key.to_s
      end

      return_value
    end

    # this purges all options
    #
    # @return [Options] self
    def reset!
      @opts = []

      self
    end

    # Add the values of one `Options` into another
    # @param other [Options] instance of `Options`
    # @return [Options]
    def +(other)
      raise TypeError, "Options type expected, #{other.class} given" unless other.is_a? Options

      update other.instance_variable_get(:@opts)

      self
    end

    # (see #opts)
    def to_s
      opts
    end

    # @return [Hash] hash of the `Options`
    def to_h
      @opts.map(&split).to_h
    end

    private

    def split
      ->(entry) { entry.split('=') }
    end

    def parse(other)
      return other.split('&').map(&split).to_h if other.is_a? String

      other.map(&split).to_h
    end

    def update(other)
      return self unless other

      build(parse(other))
    end
  end
end
