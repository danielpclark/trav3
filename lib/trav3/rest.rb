# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

module Trav3
  module REST
    class << self
      def create(travis, url, data)
        uri = as_uri url
        req = request_post uri
        set_headers travis, req
        set_json_body req, data
        response = get_response uri, req

        output travis, response
      end

      def delete(travis, url)
        uri = as_uri url
        req = request_delete uri
        set_headers travis, req
        response = get_response uri, req

        output travis, response
      end

      def get(travis, url, raw_reply = false)
        uri = as_uri url
        req = request_get uri
        set_headers travis, req
        response = get_response uri, req

        return response.body if raw_reply

        output travis, response
      end

      def patch(travis, url, data = {})
        uri = as_uri url
        req = request_patch uri
        set_headers travis, req
        set_json_body req, data
        response = get_response uri, req

        output travis, response
      end

      def post(travis, url, body = nil)
        uri = as_uri url
        req = request_post uri
        set_headers travis, req
        req.body = body if body
        response = get_response uri, req

        output travis, response
      end

      private

      def as_uri(url)
        URI( url )
      end

      def get_response(uri, request)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')
        http.request(request)
      end

      def output(travis, response)
        if [Net::HTTPAccepted, Net::HTTPOK, Net::HTTPCreated].include? response.code_type
          Success.new(travis, response)
        else
          RequestError.new(travis, response)
        end
      end

      def request_delete(uri)
        Net::HTTP::Delete.new(uri.request_uri)
      end

      def request_get(uri)
        Net::HTTP::Get.new(uri.request_uri)
      end

      def request_patch(uri)
        Net::HTTP::Patch.new(uri.request_uri)
      end

      def request_post(uri)
        Net::HTTP::Post.new(uri.request_uri)
      end

      def set_headers(travis, request)
        travis.headers.each_pair do |header, value|
          request[header] = value
        end
      end

      def set_json_body(req, data = {})
        req.body = JSON.generate(data) unless data.empty?
      end
    end
  end
end
