require 'spec_helper'

RSpec.describe Trav3::Headers do
  let(:opts) { build :headers }

  describe '#build' do
    it 'creates a url friendly parameter list' do
      expect(opts.to_h).to eq({a: :b, c: :d})
    end

    it 'appends to current headers' do
      opts.build(e: :f)
      expect(opts.to_h).to eq({a: :b, c: :d, e: :f})
    end
  end

  describe '#remove' do
    it 'removes a parameter' do
      opts.remove(:a)
      expect(opts.to_h).to eq({c: :d})
    end

    it 'can return an empty string when empty' do
      opts.remove(:a)
      opts.remove(:c)
      expect(opts.to_h).to be_empty
    end
  end

  describe '#+' do
    it 'merges two headers together' do
      result = opts.build(w: :x) + opts.build(y: :z)
      expect(result.to_h).to include({w: :x, y: :z})
    end
  end
end
