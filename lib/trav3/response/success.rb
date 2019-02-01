# frozen_string_literal: true

module Trav3
  class Success < Response
    # @return [Pagination]
    def page
      Trav3::Pagination.new(travis, self)
    end

    # @return [Boolean]
    def success?
      true
    end

    # @return [Boolean]
    def failure?
      false
    end
  end
end
