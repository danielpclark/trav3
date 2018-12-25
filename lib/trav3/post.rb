# frozen_string_literal: true
require 'net/http'
require 'uri'
require 'json'

module Trav3
  module POST
    def self.call(url, headers = {}, fields={})
      uri = URI( url.sub(/\?.*$/, '') )
      req = Net::HTTP::Post.new(uri.request_uri)
      headers.each_pair { |header, value|
        req[header] = value
      }
      req.set_form_data(**fields)
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
