# frozen_string_literal: true

module Trav3
  class InvalidAPIEndpoint < StandardError
    def message
      "The API endpoint must be either
      'https://api.travis-ci.com' or
      'https://api.travis-ci.org'"
    end
  end
end
