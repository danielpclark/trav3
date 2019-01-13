FactoryBot.define do
  RequestError = Trav3::RequestError
  factory :request_error do
    initialize_with do
      dbl = double
      allow(dbl).to receive(:body).and_return( { a: :b, c: :d }.to_json )
      new(FactoryBot.build(:travis), dbl)
    end
  end
end
