# frozen_string_literal: true
require 'trav3/version'
require 'trav3/options'
require 'trav3/result'
require 'trav3/get'

# Trav3 project namespace
module Trav3
  API_ROOT = 'https://api.travis-ci.org'

  # Abstract base class for Travis CI v3 API
  #
  # @author Daniel P. Clark <6ftdan@gmail.com>
  # @!attribute [r] options
  #   @return [Options] Request options object
  class Travis
    API_ENDPOINT = "#{API_ROOT}/v3"
    attr_reader :options

    # @param repo [String] github_username/repository_name
    # @raise [InvalidRepository] if given input does not
    #   conform to valid repository identifier format
    # @return [Travis]
    def initialize(repo)
      raise InvalidRepository unless repo.is_a?(String) and
        Regexp.new(/(^\d+$)|(^\w+(?:\/|%2F){1}\w+$)/) === repo

      @repo = repo.gsub(/\//, '%2F')
      defaults(limit: 25)
    end

    # Set the default options for requests of collections
    #
    # @overload defaults(key => value)
    #   Set as many options as you'd like for collection requests
    #   @param key [Symbol, String] name for value to set
    #   @param value [Symbol, String, Integer] value for key
    # @return [self]
    def defaults(**args)
      (@options ||= Options.new).build(**args)
      self
    end

    # # Owner
    # This will be either a user or organization.
    # 
    # ## Attributes
    # **Minimal Representation**<br />
    # Included when the resource is returned as part of another resource.
    #     
    #     Name    Type     Description
    #     id      Integer  Value uniquely identifying the owner.
    #     login   String   User or organization login set on GitHub.
    #
    # **Standard Representation**<br />
    # Included when the resource is the main response of a request, or is eager loaded.
    #    
    #     Name        Type     Description
    #     id          Integer  Value uniquely identifying the owner.
    #     login       String   User or organization login set on GitHub.
    #     name        String   User or organization name set on GitHub.
    #     github_id   Integer  User or organization id set on GitHub.
    #     avatar_url  String   Link to user or organization avatar (image) set on GitHub.
    #
    # **Additional Attributes**<br />
    #    
    #     Name           Type           Description
    #     repositories   [Repository]   Repositories belonging to this account.
    #
    # ## Actions
    # **Find**<br />
    # This returns an individual owner. It is possible to use the GitHub login or github_id in the request.
    # 
    # GET <code>/owner/{owner.login}</code>
    #    
    #     Template Variable  Type      Description
    #     owner.login        String    User or organization login set on GitHub.
    #
    #     Query Parameter    Type      Description
    #     include            [String]  List of attributes to eager load.
    #
    #     Example: GET /owner/danielpclark
    # 
    # GET <code>/owner/{user.login}</code>
    #    
    #     Template Variable  Type      Description
    #     user.login         String    Login set on Github.
    #    
    #     Query Parameter    Type      Description
    #     include            [String]  List of attributes to eager load.
    #    
    #     Example: GET /owner/danielpclark
    # 
    # GET <code>/owner/{organization.login}</code>
    #     
    #     Template Variable   Type      Description
    #     organization.login  String    Login set on GitHub.
    #    
    #     Query Parameter     Type      Description
    #     include             [String]  List of attributes to eager load.
    #    
    #     Example: GET /owner/travis-ci
    # 
    # GET <code>/owner/github_id/{owner.github_id}</code>
    #    
    #     Template Variable   Type      Description
    #     owner.github_id     Integer   User or organization id set on GitHub.
    #    
    #     Query Parameter     Type      Description
    #     include             [String]  List of attributes to eager load.
    #    
    #     Example: GET /owner/github_id/639823
    #
    # @param owner [String] username or github ID
    # @return [Trav3::Success, Trav3::RequestError]
    def owner(owner = parse_username)
      if /^\d+$/ === owner
        get("#{self[]}/owner/github_id/#{owner}")
      else
        get("#{self[]}/owner/#{owner}")
      end
    end

    #
    # @param owner [String] username or github ID
    # @return [Trav3::Success, Trav3::RequestError]
    def repositories(owner = parse_username)
      if /^\d+$/ === owner
        get("#{self[]}/owner/github_id/#{owner}/repos#{opts}")
      else
        get("#{self[]}/owner/#{owner}/repos#{opts}")
      end
    end

    #
    # @param repo [String] github_username/repository_name
    # @raise [InvalidRepository] if given input does not
    #   conform to valid repository identifier format
    # @return [Trav3::Success, Trav3::RequestError]
    def repository(repo = @repo)
      raise InvalidRepository unless repo.is_a?(String) and
        Regexp.new(/(^\d+$)|(^\w+(?:\/|%2F){1}\w+$)/) === repo

      get("#{self[]}/repo/#{repo.gsub(/\//, '%2F')}")
    end

    # @return [Trav3::Success, Trav3::RequestError]
    def builds
      get("#{self[true]}/builds#{opts}")
    end

    # @param id [String, Integer] the build id number
    # @return [Trav3::Success, Trav3::RequestError]
    def build(id)
      get("#{self[]}/build/#{id}")
    end

    # @param id [String, Integer] the build id number
    # @return [Trav3::Success, Trav3::RequestError]
    def build_jobs(id)
      get("#{self[]}/build/#{id}/jobs")
    end

    # @param id [String, Integer] the job id number
    # @return [Trav3::Success, Trav3::RequestError]
    def job(id)
      get("#{self[]}/job/#{id}")
    end

    # @param id [String, Integer] the job id number
    # @return [Trav3::Success, Trav3::RequestError]
    def log(id)
      get("#{self[]}/job/#{id}/log")
    end

    # @param id [String, Integer] the job id number
    # @return [Trav3::Success, Trav3::RequestError]
    def text_log(id)
      get("#{self[]}/job/#{id}/log.txt")
    end

    # @private
    def [](repository = false)
      [API_ENDPOINT].tap {|a| a.push("repo/#{@repo}") if repository }.join('/')
    end
    private :[]

    def opts
      @options
    end
    private :opts

    def get(x)
      Trav3::GET.(x)
    end
    private :get

    def parse_username
      @repo[/.*?(?=(?:\/|%2F)|$)/]
    end
    private :parse_username
  end
end
