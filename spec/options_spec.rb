require 'spec_helper'

RSpec.describe Trav3::Options do
  let(:opts) { build :options }

  describe '#build' do
    it 'creates a url friendly parameter list' do
      expect('?a=b&c=d').to eq opts.to_s
    end

    it 'appends to current options' do
      opts.build(e: :f)
      expect('?a=b&c=d&e=f').to eq opts.to_s
    end
  end

  describe '#remove' do
    it 'removes a parameter' do
      opts.remove(:a)
      expect('?c=d').to eq opts.to_s
    end
  end

  describe '#to_h' do
    it 'creates a valid hash from the options instance' do
      expect(opts.to_h).to eq({'c' => 'd', 'a' => 'b'})
    end
  end
end
