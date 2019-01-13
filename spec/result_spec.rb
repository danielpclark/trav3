require 'spec_helper'

RSpec.describe Trav3::Response do
  let(:response) { build :response }
  describe '#success?' do
    it 'raises an unimplemented error' do
      expect { response.success? }.to raise_error(Trav3::Unimplemented, /not implemented/)
    end
  end

  describe '#failure?' do
    it 'raises an unimplemented error' do
      expect { response.failure? }.to raise_error(Trav3::Unimplemented, /not implemented/)
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

RSpec.describe Trav3::Success do
  let(:success) { build :success }
  describe '#success?' do
    it 'to be true' do
      expect(success.success?).to be true
    end
  end

  describe '#failure?' do
    it 'to be false' do
      expect(success.failure?).to be false
    end
  end
end

RSpec.describe Trav3::RequestError do
  let(:request_error) { build :request_error }
  describe '#success?' do
    it 'to be false' do
      expect(request_error.success?).to be false
    end
  end

  describe '#failure?' do
    it 'to be true' do
      expect(request_error.failure?).to be true
    end
  end
end
