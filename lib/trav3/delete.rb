# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength
require 'net/http'
require 'uri'

module Trav3
  module DELETE
    def self.call(travis, url)
      uri = URI( url.sub(/\?.*$/, '') )
      req = Net::HTTP::Delete.new(uri.request_uri)
      travis.headers.each_pair do |header, value|
        req[header] = value
      end
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      response = http.request(req)

      if [Net::HTTPAccepted, Net::HTTPOK].include? response.code_type
        Success.new(travis, response)
      else
        RequestError.new(travis, response)
      end
    end
  end
end
# rubocop:enable Metrics/MethodLength
