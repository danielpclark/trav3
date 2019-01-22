# frozen_string_literal: true

module Trav3
  class Unimplemented < StandardError
    def message
      'This feature is not implemented.'
    end
  end
end
