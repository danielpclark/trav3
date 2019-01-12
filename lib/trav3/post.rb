# frozen_string_literal: true
require 'net/http'
require 'uri'
require 'json'

module Trav3
  module POST
    def self.call(travis, url, fields={})
      uri = URI( url.sub(/\?.*$/, '') )
      req = Net::HTTP::Post.new(uri.request_uri)
      travis.headers.each_pair { |header, value|
        req[header] = value
      }
      req.set_form_data(**fields) unless fields.empty?
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      response = http.request(req)
      
      if [Net::HTTPAccepted, Net::HTTPOK].include? response.code_type
        Success.new(travis, response)
      else
        RequestError.new(travis, response)
      end
    end
  end
end
