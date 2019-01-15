# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength
require 'net/http'
require 'uri'
require 'json'

module Trav3
  module GET
    def self.call(travis, url, raw_reply = false)
      uri = URI(url)
      req = Net::HTTP::Get.new(uri.request_uri)
      travis.headers.each_pair do |header, value|
        req[header] = value
      end
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      response = http.request(req)

      return response.body if raw_reply

      if Net::HTTPOK == response.code_type
        Success.new(travis, response)
      else
        RequestError.new(travis, response)
      end
    end
  end
end
# rubocop:enable Metrics/MethodLength
