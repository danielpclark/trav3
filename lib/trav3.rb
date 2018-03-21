# frozen_string_literal: true
require 'trav3/version'
require 'trav3/options'
require 'trav3/headers'
require 'trav3/result'
require 'trav3/post'
require 'trav3/get'

# Trav3 project namespace
module Trav3
  API_ROOT = 'https://api.travis-ci.org'

  # An abstraction for the Travis CI v3 API
  #
  # @author Daniel P. Clark https://6ftdan.com
  # @!attribute [r] options
  #   @return [Options] Request options object
  # @!attribute [r] headers
  #   @return [Headers] Request headers object
  class Travis
    API_ENDPOINT = API_ROOT
    attr_reader :options
    attr_reader :headers

    # @param repo [String] github_username/repository_name
    # @raise [InvalidRepository] if given input does not
    #   conform to valid repository identifier format
    # @return [Travis]
    def initialize(repo)
      raise InvalidRepository unless repo.is_a?(String) and
        Regexp.new(/(^\d+$)|(^\w+(?:\/|%2F){1}\w+$)/) === repo

      @repo = repo.gsub(/\//, '%2F')
      defaults(limit: 25)
      h("Travis-API-Version": 3)
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

    # Set as many headers as you'd like for API requests
    #    
    #     h("Authorization": "token xxxxxxxxxxxxxxxxxxxxxx")
    #    
    # @overload h(key: value, ...)
    #   @param key [Symbol, String] name for value to set
    #   @param value [Symbol, String, Integer] value for key
    # @return [self]
    def h(**args)
      (@headers ||= Headers.new).build(**args)
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
    # @note POST requests require an authorization token set in the headers. See: {h}
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

    # A list of builds.
    # 
    # ## Attributes
    #     
    #     Name    Type     Description
    #     builds  [Build]  List of builds.
    #    
    # **Collection Items**
    #
    # Each entry in the builds array has the following attributes:
    #      
    #     Name                 Type        Description
    #     id                   Integer     Value uniquely identifying the build.
    #     number               String      Incremental number for a repository's builds.
    #     state                String      Current state of the build.
    #     duration             Integer     Wall clock time in seconds.
    #     event_type           String      Event that triggered the build.
    #     previous_state       String      State of the previous build (useful to see if state changed).
    #     pull_request_title   String      Title of the build's pull request.
    #     pull_request_number  Integer     Number of the build's pull request.
    #     started_at           String      When the build started.
    #     finished_at          String      When the build finished.
    #     repository           Repository  GitHub user or organization the build belongs to.
    #     branch               Branch      The branch the build is associated with.
    #     tag                  Unknown     The build's tag.
    #     commit               Commit      The commit the build is associated with.
    #     jobs                 Jobs        List of jobs that are part of the build's matrix.
    #     stages               [Stage]     The stages of a build.
    #     created_by           Owner       The User or Organization that created the build.
    #     updated_at           Unknown     The build's updated_at.
    #     request              Unknown     The build's request.
    #    
    # ## Actions
    #
    # **For Current User**
    #
    # This returns a list of builds for the current user. The result is paginated. The default limit is 100.
    # 
    # GET <code>/builds</code>
    #     
    #     Query Parameter  Type      Description
    #     include          [String]  List of attributes to eager load.
    #     limit            Integer   How many builds to include in the response. Used for pagination.
    #     limit            Integer   How many builds to include in the response. Used for pagination.
    #     offset           Integer   How many builds to skip before the first entry in the response. Used for pagination.
    #     offset           Integer   How many builds to skip before the first entry in the response. Used for pagination.
    #     sort_by          [String]  Attributes to sort builds by. Used for pagination.
    #     sort_by          [String]  Attributes to sort builds by. Used for pagination.
    #    
    #     Example: GET /builds?limit=5
    #     
    # **Sortable by:** id, started_at, finished_at, append :desc to any attribute to reverse order.
    # 
    # **Find**
    #
    # This returns a list of builds for an individual repository. It is possible to use the repository id or slug in the request. The result is paginated. Each request will return 25 results.
    # 
    # GET <code>/repo/{repository.id}/builds</code>
    #     
    #     Template Variable  Type     Description
    #     repository.id      Integer  Value uniquely identifying the repository.
    #
    #     Query Parameter       Type      Description
    #     branch.name           [String]  Filters builds by name of the git branch.
    #     build.created_by      [Owner]   Filters builds by the User or Organization that created the build.
    #     build.event_type      [String]  Filters builds by event that triggered the build.
    #     build.previous_state  [String]  Filters builds by state of the previous build (useful to see if state changed).
    #     build.state           [String]  Filters builds by current state of the build.
    #     created_by            [Owner]   Alias for build.created_by.
    #     event_type            [String]  Alias for build.event_type.
    #     include               [String]  List of attributes to eager load.
    #     limit                 Integer   How many builds to include in the response. Used for pagination.
    #     offset                Integer   How many builds to skip before the first entry in the response. Used for pagination.
    #     previous_state        [String]  Alias for build.previous_state.
    #     sort_by               [String]  Attributes to sort builds by. Used for pagination.
    #     state                 [String]  Alias for build.state.
    #
    #     Example: GET /repo/891/builds?limit=5
    #     
    # **Sortable by:** id, started_at, finished_at, append :desc to any attribute to reverse order.
    # 
    # GET <code>/repo/{repository.slug}/builds</code>
    #     
    #     Template Variable  Type    Description
    #     repository.slug    String  Same as {repository.owner.name}/{repository.name}.
    #
    #     Query Parameter       Type      Description
    #     branch.name           [String]  Filters builds by name of the git branch.
    #     build.created_by      [Owner]   Filters builds by the User or Organization that created the build.
    #     build.event_type      [String]  Filters builds by event that triggered the build.
    #     build.previous_state  [String]  Filters builds by state of the previous build (useful to see if state changed).
    #     build.state           [String]  Filters builds by current state of the build.
    #     created_by            [Owner]   Alias for build.created_by.
    #     event_type            [String]  Alias for build.event_type.
    #     include               [String]  List of attributes to eager load.
    #     limit                 Integer   How many builds to include in the response. Used for pagination.
    #     offset                Integer   How many builds to skip before the first entry in the response. Used for pagination.
    #     previous_state        [String]  Alias for build.previous_state.
    #     sort_by               [String]  Attributes to sort builds by. Used for pagination.
    #     state                 [String]  Alias for build.state.
    #
    #     Example: GET /repo/rails%2Frails/builds?limit=5
    #     
    # **Sortable by:** id, started_at, finished_at, append :desc to any attribute to reverse order.
    # 
    # @return [Success, RequestError]
    def builds
      get("#{self[true]}/builds#{opts}")
    end

    # An individual build.
    # 
    # ## Attributes
    #
    # **Minimal Representation**
    #
    # Included when the resource is returned as part of another resource.
    #      
    #     Name                 Type     Description
    #     id                   Integer  Value uniquely identifying the build.
    #     number               String   Incremental number for a repository's builds.
    #     state                String   Current state of the build.
    #     duration             Integer  Wall clock time in seconds.
    #     event_type           String   Event that triggered the build.
    #     previous_state       String   State of the previous build (useful to see if state changed).
    #     pull_request_title   String   Title of the build's pull request.
    #     pull_request_number  Integer  Number of the build's pull request.
    #     started_at           String   When the build started.
    #     finished_at          String   When the build finished.
    #    
    # **Standard Representation**
    #
    # Included when the resource is the main response of a request, or is eager loaded.
    #      
    #     Name                 Type        Description
    #     id                   Integer     Value uniquely identifying the build.
    #     number               String      Incremental number for a repository's builds.
    #     state                String      Current state of the build.
    #     duration             Integer     Wall clock time in seconds.
    #     event_type           String      Event that triggered the build.
    #     previous_state       String      State of the previous build (useful to see if state changed).
    #     pull_request_title   String      Title of the build's pull request.
    #     pull_request_number  Integer     Number of the build's pull request.
    #     started_at           String      When the build started.
    #     finished_at          String      When the build finished.
    #     repository           Repository  GitHub user or organization the build belongs to.
    #     branch               Branch      The branch the build is associated with.
    #     tag                  Unknown     The build's tag.
    #     commit               Commit      The commit the build is associated with.
    #     jobs                 Jobs        List of jobs that are part of the build's matrix.
    #     stages               [Stage]     The stages of a build.
    #     created_by           Owner       The User or Organization that created the build.
    #     updated_at           Unknown     The build's updated_at.
    #    
    # ## Actions
    #
    # **Find**
    #
    # This returns a single build.
    # 
    # GET <code>/build/{build.id}</code>
    #     
    #     Template Variable  Type     Description
    #     build.id           Integer  Value uniquely identifying the build.
    #    
    #     Query Parameter  Type      Description
    #     include          [String]  List of attributes to eager load.
    #    
    #     Example: GET /build/86601346
    #     
    # **Cancel**
    #
    # This cancels a currently running build. It will set the build and associated jobs to "state": "canceled".
    # 
    # POST <code>/build/{build.id}/cancel</code>
    #     
    #     Template Variable  Type     Description
    #     build.id           Integer  Value uniquely identifying the build.
    #    
    #     Example: POST /build/86601346/cancel
    #     
    # **Restart**
    #
    # This restarts a build that has completed or been canceled.
    # 
    # POST <code>/build/{build.id}/restart</code>
    #     
    #     Template Variable  Type     Description
    #     build.id           Integer  Value uniquely identifying the build.
    #    
    #     Example: POST /build/86601346/restart
    #    
    # @note POST requests require an authorization token set in the headers. See: {h}
    #
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
      Trav3::GET.(x, headers())
    end

    def post(x, fields = {})
      Trav3::POST.(x, headers(), fields)
    end

    def username
      @repo[/.*?(?=(?:\/|%2F)|$)/]
    end
  end
end
