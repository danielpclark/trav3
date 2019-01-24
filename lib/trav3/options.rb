# frozen_string_literal: true

module Trav3
  class Options
    def initialize(args = {})
      build(args)
    end

    def opts
      if @opts.empty?
        ''
      else
        "?#{@opts.join('&')}"
      end
    end

    def build(args = {})
      @opts ||= []

      args.each do |(key, value)|
        remove(key)
        @opts.push("#{key}=#{value}")
      end

      self
    end

    def fetch(key)
      @opts.each do |item|
        return item if key.to_s == split.call(item).first
      end

      raise KeyError, "key not found #{key}" unless block_given?

      yield
    end

    def fetch!(key, &block)
      result = fetch(key, &block)
      remove(key)
      result
    end

    def immutable
      old = @opts
      result = yield self
      @opts = old
      result
    end

    def remove(key)
      return_value = nil

      @opts = @opts.delete_if do |item|
        head, tail = split.call item

        return_value = tail if head == key.to_s
      end

      return_value
    end

    def reset!
      @opts = []

      self
    end

    def +(other)
      raise TypeError, "Options type expected, #{other.class} given" unless other.is_a? Options

      update other.instance_variable_get(:@opts)

      self
    end

    def to_s
      opts
    end

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
