require 'net/http'
require 'uri'
require 'json'
require 'trav3/result'

module Trav3
  module GET
    def self.call(url, headers = {})
      uri = URI(url)
      req = Net::HTTP::Get.new(uri.request_uri)
      headers.each_pair { |header, value|
        req[header] = value
      }
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      response = http.request(req)

      if Net::HTTPOK == response.code_type
        Success.new(response)
      else
        RequestError.new(response)
      end
    end
  end
end
