# frozen_string_literal: true

module Trav3
  class ResponseCollection
    def initialize(travis, collection)
      @travis = travis
      @collection = collection
    end

    def [](target)
      result = collection[target]
      return ResponseItem.new(travis, result) if result.is_a? Hash

      result
    end

    def dig(*target)
      return collection.dig(*target) if target.length != 1

      result = collection.dig(*target)
      return ResponseItem.new(travis, result) if result.is_a? Hash

      result
    end

    def each
      return collection.each if hash?

      collection.each do |item|
        if item.is_a?(Hash)
          yield(ResponseItem.new(travis, item))
        else
          yield(ResponseCollection.new(travis, item))
        end
      end
    end

    def fetch(idx)
      result = collection.fetch(idx) { nil }
      return ResponseItem.new(travis, result) if result.is_a? Hash
      return result if result

      # For error raising behavior
      collection.fetch(idx) unless block_given?

      yield
    end

    def first
      self[0]
    end

    def follow(idx = nil)
      return ResponseItem.new(self).follow if hash?

      result = fetch(idx)
      result.follow(travis)
    end

    def has_key?(key)
      hash? ? collection.has_key(key) : false
    end

    def keys
      hash? ? collection.keys : []
    end

    def last
      self[-1]
    end

    def values
      hash? ? collection.values : []
    end

    private

    def hash?
      collection.is_a? Hash
    end

    attr_reader :travis
    attr_reader :collection
  end
end
