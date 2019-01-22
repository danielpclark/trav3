# frozen_string_literal: true

module Trav3
  class RequestError < Response
    def success?
      false
    end

    def failure?
      true
    end
  end
end
