# frozen_string_literal: true

module Trav3
  class InvalidRepository < StandardError
    def message
      "The repository format was invalid.
  You must either provide the digit name for the repository,
  or `user/repo` or `user%2Frepo` as the name."
    end
  end
end
