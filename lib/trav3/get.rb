require 'net/http'
require 'uri'
require 'json'
require_relative './result'

module GET
  def self.call(url)
    response = Net::HTTP.get_response(URI(url))

    if Net::HTTPOK == response.code_type
      Success.new(response)
    else
      RequestError.new(response)
    end
  end
end
