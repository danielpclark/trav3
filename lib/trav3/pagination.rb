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
      get("#{API_ROOT}#{self.dig("@pagination").dig("next").dig("@href")}")
    end

    def first
      get("#{API_ROOT}#{self.dig("@pagination").dig("first").dig("@href")}")
    end

    def last
      get("#{API_ROOT}#{self.dig("@pagination").dig("last").dig("@href")}")
    end

    def get(x)
      Trav3::GET.(travis, x)
    end
    private :get

    attr_reader :travis
    private :travis
  end
end
