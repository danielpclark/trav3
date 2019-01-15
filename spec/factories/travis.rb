# frozen_string_literal: true

FactoryBot.define do
  Travis = Trav3::Travis
  factory :travis do
    initialize_with { new('danielpclark/trav3') }

    after :build do |t|
      t.h('Authorization': "token #{ENV['TRAVIS_TOKEN']}") if ENV['TRAVIS_TOKEN']
    end
  end
end
