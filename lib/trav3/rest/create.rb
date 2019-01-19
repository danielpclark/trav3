# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength
require 'net/http'
require 'uri'
require 'json'

module Trav3
  module REST
    def self.create(travis, url, **data)
      uri = URI( url.sub(/\?.*$/, '') )
      req = Net::HTTP::Post.new(uri.request_uri)
      travis.headers.each_pair do |header, value|
        req[header] = value
      end
      req.body = JSON.generate(data) unless data.empty?
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
