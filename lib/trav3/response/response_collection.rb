# frozen_string_literal: true

module Trav3
  class ResponseCollection
    extend Forwardable
    # @!macro [attach] def_delegators
    #   @!method count
    #     Forwards to $1.
    #     @see both Hash#count or Array#count
    #   @!method keys
    #     Forwards to $1.
    #     @see Hash#keys
    #   @!method values
    #     Forwards to $1.
    #     @see Hash#values
    #   @!method has_key?
    #     Forwards to $1.
    #     @see Hash#has_key?
    #   @!method key?
    #     Forwards to $1.
    #     @see Hash#key?
    #   @!method empty?
    #     Forwards to $1.
    #     @see both Hash#empty? or Array#empty?
    def_delegators :@collection, :count, :keys, :values, :has_key?, :key?, :empty?
    def initialize(travis, collection)
      @travis = travis
      @collection = collection
    end

    # Either the key or index of the item you wish to get depending on
    # if this collection is a {#hash?} or an array.
    #
    # If the item retrieved is a Hash or Array then the returned item
    # will be another instance of `ResponseCollection`.  Otherwise it will
    # be a `String` unless the target does not exist and then it will be `nil`.
    #
    # @param target [String, Integer]
    # @return [ResponseCollection, String, nil]
    def [](target)
      result = collection[target]
      return ResponseCollection.new(travis, result) if collection?(result)

      result
    end

    # (see #[])
    def dig(*target)
      dug, *rest = target

      result = collection.dig(dug)
      if collection?(result)
        rc = ResponseCollection.new(travis, result)
        return rest.empty? ? rc : rc.dig(*rest)
      end

      result
    end

    # When the inner collection is an Array every item iterated
    # over is yielded to you as a `ResponseCollection`.
    #
    # If the inner collection is a {#hash?} then this method acts
    # as though you've called `each` directly on that `Hash`.
    #
    # @yieldparam [Array, ResponseCollection]
    def each(&block)
      return collection.each(&block) if hash?

      collection.each do |item|
        yield ResponseCollection.new(travis, item)
      end
    end

    # Either the key or index of the item you wish to get depending on
    # if this collection is a {#hash?} or an array.
    #
    # If the item retrieved is a Hash or Array then the returned item
    # will be another instance of `ResponseCollection`.  Otherwise it will
    # be a `String`.
    #
    # If the target does not exist and no block was given this will raise
    # an exception.  If a block was given, then that block will be evaluated
    # and that return value returned.
    #
    # @param target [String, Integer]
    # @return [ResponseCollection, String, nil]
    def fetch(target)
      result = collection.fetch(target) { nil }
      return ResponseCollection.new(travis, result) if collection?(result)
      return result if result

      # For error raising behavior
      collection.fetch(target) unless block_given?

      yield
    end

    # When the inner collection is an Array it returns the first
    # item as either a `ResponseCollection` or a `String`.  If the
    # Array is empty it returns `nil`.
    #
    # If the inner collection is a {#hash?} then this simply returns `nil`.
    #
    # @return [ResponseCollection, String, nil]
    def first
      self[0]
    end

    # Follows `@href` link within item.
    # If `#hash?` returns `true` then `#follow` takes no parameters.
    # If `#hash?` returns `false` then `#follow` takes an index parameter
    #   for which item in the Array you wish to follow.
    #
    # @param idx [Integer] (optional parameter) index of array of item to follow `@href` url from
    # @return [Success, RequestError]
    def follow(idx = nil)
      if href? && !idx
        url = collection.fetch('@href')
        return travis.send(:get_path_with_opts, url)
      end

      result = fetch(idx)
      result.follow
    end

    # Reveals if the inner collection is a Hash or not.
    #
    # @return [Boolean]
    def hash?
      collection.is_a? Hash
    end

    # When the inner collection is an Array it returns the last
    # item as either a `ResponseCollection` or a `String`.  If the
    # Array is empty it returns `nil`.
    #
    # If the inner collection is a {#hash?} then this simply returns `nil`.
    #
    # @return [ResponseCollection, String, nil]
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
