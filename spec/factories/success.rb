FactoryBot.define do
  Success = Trav3::Success
  factory :success do
    initialize_with do
      dbl = double
      allow(dbl).to receive(:body).and_return( { a: :b, c: :d }.to_json )
      new(FactoryBot.build(:travis), dbl)
    end
  end
end
