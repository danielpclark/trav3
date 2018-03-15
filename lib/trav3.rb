# frozen_string_literal: true
require 'trav3/version'
require 'trav3/options'
require 'trav3/result'
require 'trav3/get'

module Trav3
  API_ROOT = 'https://api.travis-ci.org'

  class Travis
    API_ENDPOINT = "#{API_ROOT}/v3"
    def initialize(repo)
      raise InvalidRepository unless repo.is_a?(String) and
        Regexp.new(/(^\d+$)|(^\w+(?:\/|%2F){1}\w+$)/) === repo

      @repo = repo.gsub(/\//, '%2F')
      defaults(limit: 25)
    end

    def [](repository = nil)
      [API_ENDPOINT].tap {|a| a.push("repo/#{@repo}") if repository }.join('/')
    end
    private :[]

    def defaults(**args)
      (@options ||= Options.new).build(**args)
      self
    end

    def builds
      get("#{self[true]}/builds#{opts}")
    end

    def build(id)
      get("#{self[]}/build/#{id}")
    end

    def build_jobs(id)
      get("#{self[]}/build/#{id}/jobs")
    end

    def job(id)
      get("#{self[]}/job/#{id}")
    end

    def log(id)
      get("#{self[]}/job/#{id}/log")
    end

    def text_log(id)
      get("#{self[]}/job/#{id}/log.txt")
    end

    def opts
      @options
    end
    private :opts

    def get(x)
      Trav3::GET.(x)
    end
    private :get
  end
end
