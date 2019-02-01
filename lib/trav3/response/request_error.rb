# frozen_string_literal: true

module Trav3
  # (see Response)
  class RequestError < Response
    # @return [Boolean]
    def success?
      false
    end

    # @return [Boolean]
    def failure?
      true
    end
  end
end
