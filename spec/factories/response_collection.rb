# frozen_string_literal: true

FactoryBot.define do
  ResponseCollection = Trav3::ResponseCollection
  factory :response_collection do
    initialize_with do
      file = 'spec/fixtures/vcr_cassettes/Trav3_Travis/_repositories/gets_collection_of_repositories_for_user_id.yml'
      response = YAML.load(File.new(file).read)
                     .dig('http_interactions', 0, 'response', 'body', 'string')
      json = JSON.parse(response)
      new(FactoryBot.build(:travis), json)
    end
  end
end
