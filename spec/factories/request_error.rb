FactoryBot.define do
  RequestError = Trav3::RequestError
  factory :request_error do
    initialize_with do
      dbl = Object.new
      dbl.define_singleton_method(:body) { { a: :b, c: :d }.to_json }
      new(FactoryBot.build(:travis), dbl)
    end
  end
end
