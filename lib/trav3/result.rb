# frozen_string_literal: true
require 'forwardable'

class InvalidRepository < StandardError
  def message
    "The repository format was invlaid.
You must either provide the digit name for the repository,
or `user/repo` or `user%2Frepo` as the name."
  end
end

class Unimplemented < StandardError
  def message
    "You need to implement this method"
  end
end

class Response
  extend Forwardable
  def_delegators :@json, :[], :dig, :keys, :values, :has_key?
  def_delegators :@response, :code, :code_type, :uri, :message, :read_header,
                             :header, :value, :entity, :response, :body,
                             :decode_content, :msg, :reading_body, :read_body,
                             :http_version, :connection_close?, :connection_keep_alive?,
                             :initialize_http_header, :get_fields, :each_header
  def initialize(response)
    @response = response
    @json = JSON.parse(response.body)
  end

  def inspect
    "<#{self.class} Response>"
  end

  def success?; raise Unimplemented  end
  def failure?; raise Unimplemented  end
end

class Success < Response
  def success?; true  end
  def failure?; false end
end

class RequestError < Response
  def success?; false end
  def failure?; true  end
end
