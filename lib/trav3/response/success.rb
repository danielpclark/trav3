# frozen_string_literal: true

module Trav3
  class Success < Response
    def page
      Trav3::Pagination.new(travis, self)
    end

    def success?
      true
    end

    def failure?
      false
    end
  end
end
