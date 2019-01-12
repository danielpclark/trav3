require 'spec_helper'

RSpec.describe Trav3::Response do
  let(:response) { build :response }
  describe '#success?' do
    it 'raises an unimplemented error' do
      expect{response.success?}.to raise_error(Trav3::Unimplemented, /not implemented/)
    end
  end

  describe '#failure?' do
    it 'raises an unimplemented error' do
      expect{response.success?}.to raise_error(Trav3::Unimplemented, /not implemented/)
    end
  end

  describe '#inspect' do
    it 'returns datails of class' do
      expect(response.inspect).to include('Response')
    end

    it 'returns details of keys' do
      expect(response.inspect).to include('["a", "c"]')
    end
  end
end
