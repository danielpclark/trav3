FactoryBot.define do
  Response = Trav3::Response
  factory :response do
    initialize_with do
      dbl = Object.new
      dbl.define_singleton_method(:body) { { a: :b, c: :d }.to_json }
      new(FactoryBot.build(:travis), dbl)
    end
  end
end
