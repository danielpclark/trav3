require 'net/http'
require 'uri'
require 'json'
require 'trav3/result'

module Trav3
  module POST
    def self.call(url, fields = {})
      uri = URI(API_ROOT)
      url = url.sub(/^#{API_ROOT}/, '').sub(/\?.*$/, '')
      req = Net::HTTP::Post.new(url)
      req.set_form_data(**fields)

      response = Net::HTTP.start(uri.hostname, uri.port) {|http|
        http.request(req)
      }

      if Net::HTTPOK == response.code_type
        Success.new(response)
      else
        RequestError.new(response)
      end
    end
  end
end
