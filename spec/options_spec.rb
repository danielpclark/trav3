require 'spec_helper'

RSpec.describe Trav3::Options do
  let(:opts) { build :options }

  describe '#build' do
    it 'creates a url friendly parameter list' do
      expect(opts.to_s).to eq '?a=b&c=d'
    end

    it 'appends to current options' do
      opts.build(e: :f)
      expect(opts.to_s).to eq '?a=b&c=d&e=f'
    end
  end

  describe '#remove' do
    it 'removes a parameter' do
      opts.remove(:a)
      expect(opts.to_s).to eq '?c=d'
    end

    it 'can return an empty string when empty' do
      opts.remove(:a)
      opts.remove(:c)
      expect(opts.to_s).to be_empty
    end
  end

  describe '#to_h' do
    it 'creates a valid hash from the options instance' do
      expect(opts.to_h).to eq('c' => 'd', 'a' => 'b')
    end
  end

  describe '#+' do
    it 'merges two options together' do
      result = opts.build(w: :x) + opts.build(y: :z)
      expect(result.to_s).to include('w=x&y=z')
    end
  end
end
