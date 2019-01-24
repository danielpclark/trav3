# frozen_string_literal: true

module Trav3
  class ResponseCollection
    extend Forwardable
    def_delegators :@collection, :count, :keys, :values, :has_key?, :key?, :empty?
    def initialize(travis, collection)
      @travis = travis
      @collection = collection
    end

    def [](target)
      result = collection[target]
      return ResponseCollection.new(travis, result) if collection?(result)

      result
    end

    def dig(*target)
      return collection.dig(*target) if target.length != 1

      result = collection.dig(*target)
      return ResponseCollection.new(travis, result) if collection?(result)

      result
    end

    def each(&block)
      return collection.each(&block) if hash?

      collection.each do |item|
        yield ResponseCollection.new(travis, item)
      end
    end

    def fetch(idx)
      result = collection.fetch(idx) { nil }
      return ResponseCollection.new(travis, result) if collection?(result)
      return result if result

      # For error raising behavior
      collection.fetch(idx) unless block_given?

      yield
    end

    def first
      self[0]
    end

    def follow(idx = nil)
      if href? && !idx
        url = collection.fetch('@href')
        return travis.send(:get_path_with_opts, url)
      end

      result = fetch(idx)
      result.follow
    end

    def hash?
      collection.is_a? Hash
    end

    def last
      self[-1]
    end

    private

    def collection?(input)
      [Array, Hash].include? input.class
    end

    def href?
      collection.respond_to?(:key?) and collection.key?('@href')
    end

    attr_reader :travis
    attr_reader :collection
  end
end
