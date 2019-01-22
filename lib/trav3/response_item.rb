# frozen_string_literal: true

module Trav3
  class ResponseItem
    extend Forwardable
    def_delegators :@item, *Hash.instance_methods.-(Object.methods)
    def initialize(travis, item)
      @travis = travis
      @item = item
    end

    def follow
      url = @item.fetch('@href')
      travis.send(:get, "#{url}#{travis.send(:opts)}")
    end
  end
end
