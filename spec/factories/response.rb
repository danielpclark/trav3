# frozen_string_literal: true

FactoryBot.define do
  Response = Trav3::Response
  factory :response do
    initialize_with do
      dbl = double
      allow(dbl).to receive(:body).and_return( { a: :b, c: :d }.to_json )
      new(FactoryBot.build(:travis), dbl)
    end
  end
end
