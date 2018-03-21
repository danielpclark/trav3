# frozen_string_literal: true
require 'trav3/version'
require 'trav3/options'
require 'trav3/result'
require 'trav3/post'
require 'trav3/get'

# Trav3 project namespace
module Trav3
  API_ROOT = 'https://api.travis-ci.org'

  # Abstract base class for Travis CI v3 API
  #
  # @author Daniel P. Clark https://6ftdan.com
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

    # @overload defaults(key: value, ...)
    #   Set as many options as you'd like for collections queried via an API request
    #   @param key [Symbol, String] name for value to set
    #   @param value [Symbol, String, Integer] value for key
    # @return [self]
    def defaults(**args)
      (@options ||= Options.new).build(**args)
      self
    end

    # This will be either a user or organization.
    # 
    # ## Attributes
    #
    # **Minimal Representation**
    #
    # Included when the resource is returned as part of another resource.
    #     
    #     Name    Type     Description
    #     id      Integer  Value uniquely identifying the owner.
    #     login   String   User or organization login set on GitHub.
    #
    # **Standard Representation**
    #
    # Included when the resource is the main response of a request, or is eager loaded.
    #    
    #     Name        Type     Description
    #     id          Integer  Value uniquely identifying the owner.
    #     login       String   User or organization login set on GitHub.
    #     name        String   User or organization name set on GitHub.
    #     github_id   Integer  User or organization id set on GitHub.
    #     avatar_url  String   Link to user or organization avatar (image) set on GitHub.
    #
    # **Additional Attributes**
    #    
    #     Name           Type           Description
    #     repositories   [Repository]   Repositories belonging to this account.
    #
    # ## Actions
    #
    # **Find**
    #
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
    # @return [Success, RequestError]
    def owner(owner = username)
      if /^\d+$/ === owner
        get("#{self[]}/owner/github_id/#{owner}")
      else
        get("#{self[]}/owner/#{owner}")
      end
    end

    # A list of repositories for the current user.
    # 
    # ## Attributes
    #    
    #     Name           Type           Description
    #     repositories   [Repository]   List of repositories.
    #    
    # **Collection Items**
    #
    # Each entry in the repositories array has the following attributes:
    #     
    #     Name                Type     Description
    #     id                  Integer  Value uniquely identifying the repository.
    #     name                String   The repository's name on GitHub.
    #     slug                String   Same as {repository.owner.name}/{repository.name}.
    #     description         String   The repository's description from GitHub.
    #     github_language     String   The main programming language used according to GitHub.
    #     active              Boolean  Whether or not this repository is currently enabled on Travis CI.
    #     private             Boolean  Whether or not this repository is private.
    #     owner               Owner    GitHub user or organization the repository belongs to.
    #     default_branch      Branch   The default branch on GitHub.
    #     starred             Boolean  Whether or not this repository is starred.
    #     current_build       Build    The most recently started build (this excludes builds that have been created but have not yet started).
    #     last_started_build  Build    Alias for current_build.
    #    
    # ## Actions
    #
    # **For Owner**
    #
    # This returns a list of repositories an owner has access to.
    # 
    # GET <code>/owner/{owner.login}/repos</code>
    #    
    #     Template Variable  Type    Description
    #     owner.login        String  User or organization login set on GitHub.
    #    
    #     Query Parameter     Type       Description
    #     active              [Boolean]  Alias for repository.active.
    #     include             [String]   List of attributes to eager load.
    #     limit               Integer    How many repositories to include in the response. Used for pagination.
    #     offset              Integer    How many repositories to skip before the first entry in the response. Used for pagination.
    #     private             [Boolean]  Alias for repository.private.
    #     repository.active   [Boolean]  Filters repositories by whether or not this repository is currently enabled on Travis CI.
    #     repository.private  [Boolean]  Filters repositories by whether or not this repository is private.
    #     repository.starred  [Boolean]  Filters repositories by whether or not this repository is starred.
    #     sort_by             [String]   Attributes to sort repositories by. Used for pagination.
    #     starred             [Boolean]  Alias for repository.starred.
    #    
    #     Example: GET /owner/danielpclark/repos?limit=5&sort_by=active,name
    #     
    # **Sortable by:** id, github_id, owner_name, name, active, default_branch.last_build, append :desc to any attribute to reverse order.
    # 
    # GET <code>/owner/{user.login}/repos</code>
    #     
    #     Template Variable  Type    Description
    #     user.login         String  Login set on Github.
    #
    #     Query Parameter     Type       Description
    #     active              [Boolean]  Alias for repository.active.
    #     include             [String]   List of attributes to eager load.
    #     limit               Integer    How many repositories to include in the response. Used for pagination.
    #     offset              Integer    How many repositories to skip before the first entry in the response. Used for pagination.
    #     private             [Boolean]  Alias for repository.private.
    #     repository.active   [Boolean]  Filters repositories by whether or not this repository is currently enabled on Travis CI.
    #     repository.private  [Boolean]  Filters repositories by whether or not this repository is private.
    #     repository.starred  [Boolean]  Filters repositories by whether or not this repository is starred.
    #     sort_by             [String]   Attributes to sort repositories by. Used for pagination.
    #     starred             [Boolean]  Alias for repository.starred.
    #    
    #     Example: GET /owner/danielpclark/repos?limit=5&sort_by=active,name
    #     
    # **Sortable by:** id, github_id, owner_name, name, active, default_branch.last_build, append :desc to any attribute to reverse order.
    # 
    # GET <code>/owner/{organization.login}/repos</code>
    #     
    #     Template Variable   Type    Description
    #     organization.login  String  Login set on GitHub.
    #
    #     Query Parameter     Type       Description
    #     active              [Boolean]  Alias for repository.active.
    #     include             [String]   List of attributes to eager load.
    #     limit               Integer    How many repositories to include in the response. Used for pagination.
    #     offset              Integer    How many repositories to skip before the first entry in the response. Used for pagination.
    #     private             [Boolean]  Alias for repository.private.
    #     repository.active   [Boolean]  Filters repositories by whether or not this repository is currently enabled on Travis CI.
    #     repository.private  [Boolean]  Filters repositories by whether or not this repository is private.
    #     repository.starred  [Boolean]  Filters repositories by whether or not this repository is starred.
    #     sort_by             [String]   Attributes to sort repositories by. Used for pagination.
    #     starred             [Boolean]  Alias for repository.starred.
    #    
    #     Example: GET /owner/travis-ci/repos?limit=5&sort_by=active,name
    #     
    # **Sortable by:** id, github_id, owner_name, name, active, default_branch.last_build, append :desc to any attribute to reverse order.
    # 
    # GET <code>/owner/github_id/{owner.github_id}/repos</code>
    #     
    #     Template Variable  Type     Description
    #     owner.github_id    Integer  User or organization id set on GitHub.
    #
    #     Query Parameter     Type       Description
    #     active              [Boolean]  Alias for repository.active.
    #     include             [String]   List of attributes to eager load.
    #     limit               Integer    How many repositories to include in the response. Used for pagination.
    #     offset              Integer    How many repositories to skip before the first entry in the response. Used for pagination.
    #     private             [Boolean]  Alias for repository.private.
    #     repository.active   [Boolean]  Filters repositories by whether or not this repository is currently enabled on Travis CI.
    #     repository.private  [Boolean]  Filters repositories by whether or not this repository is private.
    #     repository.starred  [Boolean]  Filters repositories by whether or not this repository is starred.
    #     sort_by             [String]   Attributes to sort repositories by. Used for pagination.
    #     starred             [Boolean]  Alias for repository.starred.
    #    
    #     Example: GET /owner/github_id/639823/repos?limit=5&sort_by=active,name
    #     
    # **Sortable by:** id, github_id, owner_name, name, active, default_branch.last_build, append :desc to any attribute to reverse order.
    # 
    # **For Current User**<br />
    # This returns a list of repositories the current user has access to.
    # 
    # GET <code>/repos</code>
    #     
    #     Query Parameter     Type       Description
    #     active              [Boolean]  Alias for repository.active.
    #     include             [String]   List of attributes to eager load.
    #     limit               Integer    How many repositories to include in the response. Used for pagination.
    #     offset              Integer    How many repositories to skip before the first entry in the response. Used for pagination.
    #     private             [Boolean]  Alias for repository.private.
    #     repository.active   [Boolean]  Filters repositories by whether or not this repository is currently enabled on Travis CI.
    #     repository.private  [Boolean]  Filters repositories by whether or not this repository is private.
    #     repository.starred  [Boolean]  Filters repositories by whether or not this repository is starred.
    #     sort_by             [String]   Attributes to sort repositories by. Used for pagination.
    #     starred             [Boolean]  Alias for repository.starred.
    #
    #     Example: GET /repos?limit=5&sort_by=active,name
    #     
    # **Sortable by:** id, github_id, owner_name, name, active, default_branch.last_build, append :desc to any attribute to reverse order.
    #
    # @param owner [String] username or github ID
    # @return [Success, RequestError]
    def repositories(owner = username)
      if /^\d+$/ === owner
        get("#{self[]}/owner/github_id/#{owner}/repos#{opts}")
      else
        get("#{self[]}/owner/#{owner}/repos#{opts}")
      end
    end

    # An individual repository.
    # 
    # ## Attributes
    #
    # **Minimal Representation**
    #
    # Included when the resource is returned as part of another resource.
    #      
    #     Name   Type     Description
    #     id     Integer  Value uniquely identifying the repository.
    #     name   String   The repository's name on GitHub.
    #     slug   String   Same as {repository.owner.name}/{repository.name}.
    #    
    # **Standard Representation**
    #
    # Included when the resource is the main response of a request, or is eager loaded.
    #      
    #     Name             Type     Description
    #     id               Integer  Value uniquely identifying the repository.
    #     name             String   The repository's name on GitHub.
    #     slug             String   Same as {repository.owner.name}/{repository.name}.
    #     description      String   The repository's description from GitHub.
    #     github_language  String   The main programming language used according to GitHub.
    #     active           Boolean  Whether or not this repository is currently enabled on Travis CI.
    #     private          Boolean  Whether or not this repository is private.
    #     owner            Owner    GitHub user or organization the repository belongs to.
    #     default_branch   Branch   The default branch on GitHub.
    #     starred          Boolean  Whether or not this repository is starred.
    #    
    # ## Actions
    #
    # **Find**
    #
    # This returns an individual repository.
    # 
    # GET <code>/repo/{repository.id}</code>
    #     
    #     Template Variable  Type     Description
    #     repository.id      Integer  Value uniquely identifying the repository.
    #    
    #     Query Parameter  Type      Description
    #     include          [String]  List of attributes to eager load.
    #    
    #     Example: GET /repo/891
    #     
    # GET <code>/repo/{repository.slug}</code>
    #     
    #     Template Variable  Type    Description
    #     repository.slug    String  Same as {repository.owner.name}/{repository.name}.
    #    
    #     Query Parameter  Type      Description
    #     include          [String]  List of attributes to eager load.
    #    
    #     Example: GET /repo/rails%2Frails
    #     
    # **Activate**
    #
    # This will activate a repository, allowing its tests to be run on Travis CI.
    # 
    # POST <code>/repo/{repository.id}/activate</code>
    #     
    #     Template Variable  Type     Description
    #     repository.id      Integer  Value uniquely identifying the repository.
    #    
    #     Example: POST /repo/891/activate
    #     
    # POST <code>/repo/{repository.slug}/activate</code>
    #     
    #     Template Variable  Type    Description
    #     repository.slug    String  Same as {repository.owner.name}/{repository.name}.
    #    
    #     Example: POST /repo/rails%2Frails/activate
    #     
    # **Deactivate**
    # 
    # This will deactivate a repository, preventing any tests from running on Travis CI.
    # 
    # POST <code>/repo/{repository.id}/deactivate</code>
    #     
    #     Template Variable  Type     Description
    #     repository.id      Integer  Value uniquely identifying the repository.
    #    
    #     Example: POST /repo/891/deactivate
    #     
    # POST <code>/repo/{repository.slug}/deactivate</code>
    #     
    #     Template Variable  Type    Description
    #     repository.slug    String  Same as {repository.owner.name}/{repository.name}.
    #    
    #     Example: POST /repo/rails%2Frails/deactivate
    #     
    # **Star**
    #
    # This will star a repository based on the currently logged in user.
    # 
    # POST <code>/repo/{repository.id}/star</code>
    #     
    #     Template Variable  Type     Description
    #     repository.id      Integer  Value uniquely identifying the repository.
    #    
    #     Example: POST /repo/891/star
    #     
    # POST <code>/repo/{repository.slug}/star</code>
    #     
    #     Template Variable  Type    Description
    #     repository.slug    String  Same as {repository.owner.name}/{repository.name}.
    #    
    #     Example: POST /repo/rails%2Frails/star
    #     
    # **Unstar**
    #
    # This will unstar a repository based on the currently logged in user.
    # 
    # POST <code>/repo/{repository.id}/unstar</code>
    #     
    #     Template Variable  Type     Description
    #     repository.id      Integer  Value uniquely identifying the repository.
    #    
    #     Example: POST /repo/891/unstar
    #     
    # POST <code>/repo/{repository.slug}/unstar</code>
    #    
    #     Template Variable  Type    Description
    #     repository.slug    String  Same as {repository.owner.name}/{repository.name}.
    #    
    #     Example: POST /repo/rails%2Frails/unstar
    #    
    # @param repo [String] github_username/repository_name
    # @param action [String, Symbol] Optional argument for star/unstar/activate/deactivate
    # @raise [InvalidRepository] if given input does not
    #   conform to valid repository identifier format
    # @return [Success, RequestError]
    def repository(repo = repository_name, action = nil)
      raise InvalidRepository unless repo.is_a?(String) and
        Regexp.new(/(^\d+$)|(^\w+(?:\/|%2F){1}\w+$)/) === repo

      repo = repo.gsub(/\//, '%2F')

      action = '' if !%w(star unstar activate deavtivate).include? "#{action}"

      if action.empty?
        get("#{self[]}/repo/#{repo}")
      else
        post("#{self[]}/repo/#{repo}/#{action}")
      end
    end

    # @return [Success, RequestError]
    def builds
      get("#{self[true]}/builds#{opts}")
    end

    # @param id [String, Integer] the build id number
    # @return [Success, RequestError]
    def build(id)
      get("#{self[]}/build/#{id}")
    end

    # @param id [String, Integer] the build id number
    # @return [Success, RequestError]
    def build_jobs(id)
      get("#{self[]}/build/#{id}/jobs")
    end

    # @param id [String, Integer] the job id number
    # @return [Success, RequestError]
    def job(id)
      get("#{self[]}/job/#{id}")
    end

    # @param id [String, Integer] the job id number
    # @return [Success, RequestError]
    def log(id)
      get("#{self[]}/job/#{id}/log")
    end

    # @param id [String, Integer] the job id number
    # @return [Success, RequestError]
    def text_log(id)
      get("#{self[]}/job/#{id}/log.txt")
    end

    private # @private
    def [](repository = false)
      [API_ENDPOINT].tap {|a| a.push("repo/#{@repo}") if repository }.join('/')
    end

    def repository_name
      @repo
    end

    def opts
      @options
    end

    def get(x)
      Trav3::GET.(x)
    end

    def post(x, fields = {})
      Trav3::POST.(x, fields)
    end

    def username
      @repo[/.*?(?=(?:\/|%2F)|$)/]
    end
  end
end
