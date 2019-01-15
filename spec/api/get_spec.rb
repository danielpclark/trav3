# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Trav3::GET, :vcr do
  let(:t) { build :travis }

  describe '#call' do
    it 'happy path' do
      expect(t.owner).to be_an_instance_of(Trav3::Success)
    end

    it 'not happy path' do
      expect(
        t.send(:get, "#{t.send(:without_repo)}/example_fail_1234")
      ).to be_an_instance_of(Trav3::RequestError)
    end
  end
end
