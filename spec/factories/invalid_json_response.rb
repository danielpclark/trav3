# frozen_string_literal: true

FactoryBot.define do
  InvalidJsonResponse = Trav3::Response
  factory :invalid_json_response do
    initialize_with do
      dbl = double
      allow(dbl).to receive(:body).and_return( ':asdf' )
      allow(dbl).to receive(:error!).and_raise(Net::HTTPFatalError.new('Internal Server Error', 500))
      new(build(:travis), dbl)
    end
  end
end
