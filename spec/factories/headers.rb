FactoryBot.define do
  Headers = Trav3::Headers
  factory :headers do
    initialize_with { new(a: :b, c: :d) }
  end
end
