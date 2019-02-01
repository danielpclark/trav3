# frozen_string_literal: true

require 'forwardable'

module Trav3
  # The results from queries return either `Success` or `RequestError` which both
  # repsond with Hash like query methods for the JSON data or the Net::HTTP resonse object methods.
  #
  # The `Response` classes `Success` and `RequestError` forward method calls for all of the instance
  # methods of a `ResponseCollection` to the collection.  And many of the methods calls for the Net::HTTP
  # response are also available on this class and those method calls are forwarded to the response.
  class Response
    extend Forwardable
    attr_reader :travis
    # @!macro [attach] def_delegators
    #   @!method []
    #     Forwards to $1
    #     @see ResponseCollection#[]
    #   @!method count
    #     Forwards to $1.
    #     @see ResponseCollection#count
    #   @!method dig
    #     Forwards to $1
    #     @see ResponseCollection#dig
    #   @!method each
    #     Forwards to $1
    #     @see ResponseCollection#each
    #   @!method empty?
    #     Forwards to $1.
    #     @see ResponseCollection#empty?
    #   @!method fetch
    #     Forwards to $1
    #     @see ResponseCollection#fetch
    #   @!method first
    #     Forwards to $1
    #     @see ResponseCollection#first
    #   @!method follow
    #     Forwards to $1
    #     @see ResponseCollection#follow
    #   @!method has_key?
    #     Forwards to $1.
    #     @see ResponseCollection#has_key?
    #   @!method hash?
    #     Forwards to $1
    #     @see ResponseCollection#hash?
    #   @!method key?
    #     Forwards to $1.
    #     @see ResponseCollection#key?
    #   @!method last
    #     Forwards to $1
    #     @see ResponseCollection#last
    #   @!method keys
    #     Forwards to $1.
    #     @see ResponseCollection#keys
    #   @!method values
    #     Forwards to $1.
    #     @see ResponseCollection#values
    def_delegators :@collection, *ResponseCollection.instance_methods(false)
    # @!macro [attach] def_delegators
    #   @!method body
    #     Forwards to $1
    #     @see Net::HTTPResponse#body
    #   @!method code
    #     Forwards to $1
    #     @see Net::HTTPResponse#code
    #   @!method code_type
    #     Forwards to $1
    #     @see Net::HTTPResponse#code_type
    #   @!method decode_content
    #     Forwards to $1
    #     @see Net::HTTPResponse#decode_content
    #   @!method each_header
    #     Forwards to $1
    #     @see Net::HTTPHeader#each_header
    #   @!method entity
    #     Forwards to $1
    #     @see Net::HTTPResponse#entity
    #   @!method get_fields
    #     Forwards to $1
    #     @see Net::HTTPHeader#get_fields
    #   @!method header
    #     Forwards to $1
    #     @see Net::HTTPResponse#header
    #   @!method http_version
    #     Forwards to $1
    #     @see Net::HTTPResponse#http_version
    #   @!method message
    #     Forwards to $1
    #     @see Net::HTTPResponse#message
    #   @!method msg
    #     Forwards to $1
    #     @see Net::HTTPResponse#msg
    #   @!method read_body
    #     Forwards to $1
    #     @see Net::HTTPResponse#read_body
    #   @!method read_header
    #     Forwards to $1
    #     @see Net::HTTPResponse#read_header
    #   @!method reading_body
    #     Forwards to $1
    #     @see Net::HTTPResponse#reading_body
    #   @!method response
    #     Forwards to $1
    #     @see Net::HTTPResponse#response
    #   @!method uri
    #     Forwards to $1
    #     @see Net::HTTPResponse#uri
    #   @!method value
    #     Forwards to $1
    #     @see Net::HTTPResponse#value
    def_delegators :@response, :body, :code, :code_type, :decode_content,
                   :each_header, :entity, :get_fields, :header, :http_version,
                   :message, :msg, :read_body, :read_header, :reading_body, :response,
                   :uri, :value
    def initialize(travis, response)
      @travis = travis
      @response = response
      @collection = begin
                      result = JSON.parse(response&.body || '{}')
                      ResponseCollection.new(travis, result)
                    rescue JSON::ParserError
                      response.error!
                    end
    end

    # Class name and keys of response
    def inspect
      "<#{self.class} Response: keys = #{keys}>"
    end

    # @abstract
    def success?
      raise Unimplemented
    end

    # @abstract
    def failure?
      raise Unimplemented
    end
    private :travis
  end
end
