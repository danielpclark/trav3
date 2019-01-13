# frozen_string_literal: true

module Trav3
  class Pagination
    def initialize(travis, result)
      @travis = travis
      @result = result
    end

    def dig(opt)
      @result.dig(opt)
    end

    def next
      get("#{API_ROOT}#{dig('@pagination').dig('next').dig('@href')}")
    end

    def first
      get("#{API_ROOT}#{dig('@pagination').dig('first').dig('@href')}")
    end

    def last
      get("#{API_ROOT}#{dig('@pagination').dig('last').dig('@href')}")
    end

    def get(url)
      Trav3::GET.call(travis, url)
    end
    private :get

    attr_reader :travis
    private :travis
  end
end
