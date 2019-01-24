# frozen_string_literal: true

FactoryBot.define do
  Response = Trav3::Response
  InvalidJsonResponse = Response
  factory :response do
    initialize_with do
      dbl = double
      allow(dbl).to receive(:body).and_return( { a: :b, c: :d }.to_json )
      new(build(:travis), dbl)
    end
  end

  factory :invalid_json_response do
    initialize_with do
      dbl = double
      allow(dbl).to receive(:body).and_return( ':asdf' )
      allow(dbl).to receive(:error!).and_raise(Net::HTTPFatalError.new('Internal Server Error', 500))
      new(build(:travis), dbl)
    end
  end
end
