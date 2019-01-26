# frozen_string_literal: true

module Trav3
  class EnvVarError < StandardError
    def message
      "You must provide the keys `name`, `value`, and `public`\
      where name and value are given String values and public is a Boolean."
    end
  end
end
