# frozen_string_literal: true

FactoryBot.define do
  Options = Trav3::Options
  factory :options do
    initialize_with { new(a: :b, c: :d) }
  end
end
