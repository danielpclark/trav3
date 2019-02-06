# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Trav3::ResponseCollection do
  let(:rc) { build :response_collection }
  let(:collection) { rc['repositories'] }

  describe '#dig' do
    context 'digs collections as ResponseCollections' do
      it 'with arrays' do
        expect(rc.dig('repositories')).to be_an_instance_of Trav3::ResponseCollection
      end

      it 'with hashes' do
        expect(collection.first.dig('owner')).to be_an_instance_of Trav3::ResponseCollection
      end
    end

    it 'non collections are untouched' do
      expect(collection.first.dig('@representation')).to be_an_instance_of String
    end

    it 'defaults to normal dig behavior in multiple query' do
      expect(rc.dig('repositories', 0)).to be_an_instance_of Trav3::ResponseCollection
    end
  end

  describe '#each' do
    context 'for array' do
      it 'wraps each item yielded' do
        collection.each do |item|
          expect(item).to be_an_instance_of Trav3::ResponseCollection
        end
      end
    end

    context 'for hash' do
      it 'doesn\'t wrap each item yielded' do
        rc.each do |item|
          expect(item).to_not be_an_instance_of Trav3::ResponseCollection
        end
      end
    end
  end

  describe '#fetch' do
    it 'fails to fetch when invalid index' do
      expect { collection.fetch(26) }.to raise_error(IndexError, /index/)
    end

    it 'fails to fetch when invalid key' do
      expect { rc.fetch(:foo) }.to raise_error(KeyError, /key/)
    end

    it 'yields as last resort' do
      expect(rc.fetch(:foo) { :bar }).to be(:bar)
    end

    it 'fetches an array as a ResponseCollection' do
      expect(rc.fetch('repositories')).to be_an_instance_of Trav3::ResponseCollection
    end
  end

  describe '#first' do
    context 'outer layer' do
      it 'has no first' do
        first = rc.first
        expect(first).to be_nil
      end
    end

    context 'collection results' do
      it 'gets first item' do
        first = collection.first
        expect(first).to be_an_instance_of Trav3::ResponseCollection
      end
    end
  end

  describe '#follow', :vcr do
    it 'can follow an @href' do
      follow = collection.first.follow
      expect(follow).to be_an_instance_of Trav3::Success
      expect(follow.warnings).to be_nil
    end

    it 'can follow the @href of an indexed item' do
      follow = collection.follow(1)
      expect(follow).to be_an_instance_of Trav3::Success
    end
  end

  describe '#last' do
    context 'outer layer' do
      it 'has no last' do
        last = rc.last
        expect(last).to be_nil
      end
    end

    context 'collection results' do
      it 'gets last item' do
        last = collection.last
        expect(last).to be_an_instance_of Trav3::ResponseCollection
      end
    end
  end
end
