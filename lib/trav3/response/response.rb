# frozen_string_literal: true

require 'forwardable'

module Trav3
  class Response
    extend Forwardable
    attr_reader :travis
    def_delegators :@collection, *ResponseCollection.instance_methods.-(Object.methods)
    def_delegators :@response, :code, :code_type, :uri, :message, :read_header,
                   :header, :value, :entity, :response, :body, :decode_content,
                   :msg, :reading_body, :read_body, :http_version,
                   :connection_close?, :connection_keep_alive?,
                   :initialize_http_header, :get_fields, :each_header
    def initialize(travis, response)
      @travis = travis
      @response = response
      @collection = begin
                      result = JSON.parse(response.body)
                      ResponseCollection.new(travis, result)
                    rescue JSON::ParserError
                      response.error!
                    end
    end

    def inspect
      "<#{self.class} Response: keys = #{keys}>"
    end

    def success?
      raise Unimplemented
    end

    def failure?
      raise Unimplemented
    end
    private :travis
  end
end
