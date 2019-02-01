# frozen_string_literal: true

module Trav3
  class Pagination
    attr_reader :travis
    def initialize(travis, result)
      @travis = travis
      @result = result
    end

    # Next page of results
    # @return [Success, RequestError]
    def next
      get(action(:next))
    end

    # First page of results
    # @return [Success, RequestError]
    def first
      get(action(:first))
    end

    # Last page of results
    # @return [Success, RequestError]
    def last
      get(action(:last))
    end

    private # @private

    def action(action)
      dig('@pagination').dig(action.to_s).dig('@href')
    end

    def dig(opt)
      @result.dig(opt)
    end

    def get(path)
      travis.send(:get_path, path.to_s)
    end
    private :travis
  end
end
