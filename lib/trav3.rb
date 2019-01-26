# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
require 'trav3/version'
require 'forwardable'
require 'trav3/errors'
require 'trav3/response'
require 'trav3/pagination'
require 'trav3/options'
require 'trav3/headers'
require 'trav3/rest'

# Trav3 project namespace
module Trav3
  # An abstraction for the Travis CI v3 API
  #
  # @author Daniel P. Clark https://6ftdan.com
  # @!attribute [r] api_endpoint
  #   @return [String] API endpoint
  # @!attribute [r] options
  #   @return [Options] Request options object
  # @!attribute [r] headers
  #   @return [Headers] Request headers object
  class Travis
    attr_reader :api_endpoint
    attr_reader :options
    attr_reader :headers

    # @param repo [String] github_username/repository_name
    # @raise [InvalidRepository] if given input does not
    #   conform to valid repository identifier format
    # @return [Travis]
    def initialize(repo)
      @api_endpoint = 'https://api.travis-ci.org'

      self.repository = repo

      initial_defaults
    end
    # rubocop:disable Lint/Void

    # Set as the API endpoint
    #
    # @param endpoint [String] name for value to set
    # @return [self]
    def api_endpoint=(endpoint)
      validate_api_endpoint endpoint

      @api_endpoint = endpoint

      self
    end

    # Set the authorization token in the requests' headers
    #
    # @param token [String] sets authorization token header
    # @return [self]
    def authorization=(token)
      validate_string token
      h('Authorization': "token #{token}")
      self
    end

    # Set as many options as you'd like for collections queried via an API request
    #
    # @overload defaults(key: value, ...)
    #   @param key [Symbol] name for value to set
    #   @param value [Symbol, String, Integer] value for key
    # @return [self]
    def defaults(**args)
      (@options ||= Options.new).build(args)
      self
    end

    # Set as many headers as you'd like for API requests
    #
    #     h("Authorization": "token xxxxxxxxxxxxxxxxxxxxxx")
    #
    # @overload h(key: value, ...)
    #   @param key [Symbol] name for value to set
    #   @param value [Symbol, String, Integer] value for key
    # @return [self]
    def h(**args)
      (@headers ||= Headers.new).build(args)
      self
    end

    # Change the repository this instance of `Trav3::Travis` uses.
    #
    # @param repo_name [String] github_username/repository_name
    # @return [self]
    def repository=(repo_name)
      validate_repo_format repo_name
      @repo = sanitize_repo_name repo_name
      self
    end
    # rubocop:enable Lint/Void

    # Please Note that the naming of this endpoint may be changed. Our naming convention for this information is in flux. If you have suggestions for how this information should be presented please leave us feedback by commenting in this issue here or emailing support support@travis-ci.com.
    #
    # A list of all the builds in an "active" state, either created or started.
    #
    # ## Attributes
    #
    #     Name    Type    Description
    #     builds  Builds  The active builds.
    #
    # ## Actions
    #
    # **For Owner**
    #
    # Returns a list of "active" builds for the owner.
    #
    # GET <code>/owner/{owner.login}/active</code>
    #
    #     Template Variable  Type    Description
    #     owner.login        String  User or organization login set on GitHub.
    #     Query Parameter  Type      Description
    #     include          [String]  List of attributes to eager load.
    #
    #     Example: GET /owner/danielpclark/active
    #
    # GET <code>/owner/{user.login}/active</code>
    #
    #     Template Variable  Type    Description
    #     user.login         String  Login set on GitHub.
    #     Query Parameter  Type      Description
    #     include          [String]  List of attributes to eager load.
    #
    #     Example: GET /owner/danielpclark/active
    #
    # GET <code>/owner/{organization.login}/active</code>
    #
    #     Template Variable   Type    Description
    #     organization.login  String  Login set on GitHub.
    #     Query Parameter  Type      Description
    #     include          [String]  List of attributes to eager load.
    #
    #     Example: GET /owner/travis-ci/active
    #
    # GET <code>/owner/github_id/{owner.github_id}/active</code>
    #
    #     Template Variable  Type     Description
    #     owner.github_id    Integer  User or organization id set on GitHub.
    #     Query Parameter  Type      Description
    #     include          [String]  List of attributes to eager load.
    #
    #     Example: GET /owner/github_id/639823/active
    #
    # @param owner [String] username, organization name, or github id
    # @return [Success, RequestError]
    def active(owner = username)
      if number? owner
        get("#{without_repo}/owner/github_id/#{owner}/active")
      else
        get("#{without_repo}/owner/#{owner}/active")
      end
    end

    # The branch of a GitHub repository. Useful for obtaining information about the last build on a given branch.
    #
    # **If querying using the repository slug, it must be formatted using {http://www.w3schools.com/tags/ref_urlencode.asp standard URL encoding}, including any special characters.**
    #
    # ## Attributes
    #
    # **Minimal Representation**
    #
    # Included when the resource is returned as part of another resource.
    #
    #     Name  Type    Description
    #     name  String  Name of the git branch.
    #
    # **Standard Representation**
    #
    # Included when the resource is the main response of a request, or is {https://developer.travis-ci.com/eager-loading eager loaded}.
    #
    #     Name              Type        Description
    #     name              String      Name of the git branch.
    #     repository        Repository  GitHub user or organization the branch belongs to.
    #     default_branch    Boolean     Whether or not this is the resposiotry's default branch.
    #     exists_on_github  Boolean     Whether or not the branch still exists on GitHub.
    #     last_build        Build       Last build on the branch.
    #
    # **Additional Attributes**
    #
    #     Name           Type     Description
    #     recent_builds  [Build]  Last 10 builds on the branch (when `include=branch.recent_builds` is used).
    #
    # ## Actions
    #
    # **Find**
    #
    # This will return information about an individual branch. The request can include either the repository id or slug.
    #
    # GET <code>/repo/{repository.id}/branch/{branch.name}</code>
    #
    #     Template Variable  Type     Description
    #     repository.id      Integer  Value uniquely identifying the repository.
    #     branch.name        String   Name of the git branch.
    #     Query Parameter  Type      Description
    #     include          [String]  List of attributes to eager load.
    #
    #     Example: GET /repo/891/branch/master
    #
    # GET <code>/repo/{repository.slug}/branch/{branch.name}</code>
    #
    #     Template Variable  Type    Description
    #     repository.slug    String  Same as {repository.owner.name}/{repository.name}.
    #     branch.name        String  Name of the git branch.
    #     Query Parameter  Type      Description
    #     include          [String]  List of attributes to eager load.
    #
    #     Example: GET /repo/rails%2Frails/branch/master
    #
    # @param name [String] the branch name for the current repository
    # @return [Success, RequestError]
    def branch(name)
      get("#{with_repo}/branch/#{name}")
    end

    # A list of branches.
    #
    # **If querying using the repository slug, it must be formatted using {http://www.w3schools.com/tags/ref_urlencode.asp standard URL encoding}, including any special characters.**
    #
    # ##Attributes
    #
    #     Name      Type      Description
    #     branches  [Branch]  List of branches.
    #
    # **Collection Items**
    #
    # Each entry in the **branches** array has the following attributes:
    #
    #     Name              Type        Description
    #     name              String      Name of the git branch.
    #     repository        Repository  GitHub user or organization the branch belongs to.
    #     default_branch    Boolean     Whether or not this is the resposiotry's default branch.
    #     exists_on_github  Boolean     Whether or not the branch still exists on GitHub.
    #     last_build        Build       Last build on the branch.
    #     recent_builds    [Build]      Last 10 builds on the branch (when `include=branch.recent_builds` is used).
    #
    # ## Actions
    #
    # **Find**
    #
    # This will return a list of branches a repository has on GitHub.
    #
    # GET <code>/repo/{repository.id}/branches</code>
    #
    #     Template Variable  Type     Description
    #     repository.id      Integer  Value uniquely identifying the repository.
    #     Query Parameter          Type       Description
    #     branch.exists_on_github  [Boolean]  Filters branches by whether or not the branch still exists on GitHub.
    #     exists_on_github         [Boolean]  Alias for branch.exists_on_github.
    #     include                  [String]   List of attributes to eager load.
    #     limit                    Integer    How many branches to include in the response. Used for pagination.
    #     offset                   Integer    How many branches to skip before the first entry in the response. Used for pagination.
    #     sort_by                  [String]   Attributes to sort branches by. Used for pagination.
    #
    #     Example: GET /repo/891/branches?limit=5&exists_on_github=true
    #
    # **Sortable by:** <code>name</code>, <code>last_build</code>, <code>exists_on_github</code>, <code>default_branch</code>, append <code>:desc</code> to any attribute to reverse order.
    # The default value is <code>default_branch</code>,<code>exists_on_github</code>,<code>last_build:desc</code>.
    #
    # GET <code>/repo/{repository.slug}/branches</code>
    #
    #     Template Variable  Type    Description
    #     repository.slug    String  Same as {repository.owner.name}/{repository.name}.
    #     Query Parameter          Type       Description
    #     branch.exists_on_github  [Boolean]  Filters branches by whether or not the branch still exists on GitHub.
    #     exists_on_github         [Boolean]  Alias for branch.exists_on_github.
    #     include                  [String]   List of attributes to eager load.
    #     limit                    Integer    How many branches to include in the response. Used for pagination.
    #     offset                   Integer    How many branches to skip before the first entry in the response. Used for pagination.
    #     sort_by                  [String]   Attributes to sort branches by. Used for pagination.
    #
    #     Example: GET /repo/rails%2Frails/branches?limit=5&exists_on_github=true
    #
    # **Sortable by:** <code>name</code>, <code>last_build</code>, <code>exists_on_github</code>, <code>default_branch</code>, append <code>:desc</code> to any attribute to reverse order.
    # The default value is <code>default_branch</code>,<code>exists_on_github</code>,<code>last_build:desc</code>.
    #
    # @return [Success, RequestError]
    def branches
      get("#{with_repo}/branches#{opts}")
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
    # @note POST requests require an authorization token set in the headers. See: {authorization=}
    #
    # @param build_id [String, Integer] the build id number
    # @param option [Symbol] options for :cancel or :restart
    # @raise [TypeError] if given build id is not a number
    # @return [Success, RequestError]
    def build(build_id, option = nil)
      validate_number build_id

      case option
      when :cancel
        post("#{without_repo}/build/#{build_id}/cancel")
      when :restart
        post("#{without_repo}/build/#{build_id}/restart")
      else
        get("#{without_repo}/build/#{build_id}")
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
    # This returns a list of builds for the current user. The result is paginated.
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
    # **Sortable by:** <code>id</code>, <code>started_at</code>, <code>finished_at</code>, append <code>:desc</code> to any attribute to reverse order.
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
    # **Sortable by:** <code>id</code>, <code>started_at</code>, <code>finished_at</code>, append <code>:desc</code> to any attribute to reverse order.
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
    # **Sortable by:** <code>id</code>, <code>started_at</code>, <code>finished_at</code>, append <code>:desc</code> to any attribute to reverse order.
    #
    # @return [Success, RequestError]
    def builds
      get("#{with_repo}/builds#{opts}")
    end

    # A list of jobs.
    #
    # ## Attributes
    #
    #     Name  Type  Description
    #     jobs  [Job]  List of jobs.
    #
    # **Collection Items**
    #
    # Each entry in the jobs array has the following attributes:
    #
    #     Name           Type        Description
    #     id             Integer     Value uniquely identifying the job.
    #     allow_failure  Unknown     The job's allow_failure.
    #     number         String      Incremental number for a repository's builds.
    #     state          String      Current state of the job.
    #     started_at     String      When the job started.
    #     finished_at    String      When the job finished.
    #     build          Build       The build the job is associated with.
    #     queue          String      Worker queue this job is/was scheduled on.
    #     repository     Repository  GitHub user or organization the job belongs to.
    #     commit         Commit      The commit the job is associated with.
    #     owner          Owner       GitHub user or organization the job belongs to.
    #     stage          [Stage]     The stages of a job.
    #     created_at     String      When the job was created.
    #     updated_at     String      When the job was updated.
    #     config         Object      The job's config.
    #
    # ## Actions
    #
    # **Find**
    #
    # This returns a list of jobs belonging to an individual build.
    #
    # GET <code>/build/{build.id}/jobs</code>
    #
    #     Template Variable  Type     Description
    #     build.id           Integer  Value uniquely identifying the build.
    #
    #     Query Parameter  Type      Description
    #     include          [String]  List of attributes to eager load.
    #
    #     Example: GET /build/86601346/jobs
    #
    # **For Current User**
    #
    # This returns a list of jobs a current user has access to.
    #
    # GET <code>/jobs</code>
    #
    #     Query Parameter  Type      Description
    #     active           Unknown   Alias for job.active.
    #     created_by       Unknown   Alias for job.created_by.
    #     include          [String]  List of attributes to eager load.
    #     job.active       Unknown   Documentation missing.
    #     job.created_by   Unknown   Documentation missing.
    #     job.state        [String]  Filters jobs by current state of the job.
    #     limit            Integer   How many jobs to include in the response. Used for pagination.
    #     offset           Integer   How many jobs to skip before the first entry in the response. Used for pagination.
    #     sort_by          [String]  Attributes to sort jobs by. Used for pagination.
    #     state            [String]  Alias for job.state.
    #
    #     Example: GET /jobs?limit=5
    #
    # **Sortable by:** <code>id</code>, append <code>:desc</code> to any attribute to reverse order.
    # The default value is id:desc.
    #
    # @param build_id [String, Integer] the build id number
    # @return [Success, RequestError]
    def build_jobs(build_id)
      get("#{without_repo}/build/#{build_id}/jobs")
    end

    # A list of caches.
    #
    # If querying using the repository slug, it must be formatted using {http://www.w3schools.com/tags/ref_urlencode.asp standard URL encoding}, including any special characters.
    #
    # ## Attributes
    #
    #     Name    Type    Description
    #     branch  String  The branch the cache belongs to.
    #     match   String  The string to match against the cache name.
    #
    # ## Actions
    #
    # **Find**
    #
    # This returns all the caches for a repository.
    #
    # It's possible to filter by branch or by regexp match of a string to the cache name.
    #
    # ```bash
    # curl \
    #   -H "Content-Type: application/json" \
    #   -H "Travis-API-Version: 3" \
    #   -H "Authorization: token xxxxxxxxxxxx" \
    #   https://api.travis-ci.com/repo/1234/caches?branch=master
    # ```
    #
    # ```bash
    # curl \
    #   -H "Content-Type: application/json" \
    #   -H "Travis-API-Version: 3" \
    #   -H "Authorization: token xxxxxxxxxxxx" \
    #   https://api.travis-ci.com/repo/1234/caches?match=linux
    # ```
    #
    # GET <code>/repo/{repository.id}/caches</code>
    #
    #     Template Variable  Type     Description
    #     repository.id      Integer  Value uniquely identifying the repository.
    #     Query Parameter  Type      Description
    #     branch           [String]  Alias for caches.branch.
    #     caches.branch    [String]  Filters caches by the branch the cache belongs to.
    #     caches.match     [String]  Filters caches by the string to match against the cache name.
    #     include          [String]  List of attributes to eager load.
    #     match            [String]  Alias for caches.match.
    #
    #     Example: GET /repo/891/caches
    #
    # GET <code>/repo/{repository.slug}/caches</code>
    #
    #     Template Variable  Type    Description
    #     repository.slug    String  Same as {repository.owner.name}/{repository.name}.
    #     Query Parameter  Type      Description
    #     branch           [String]  Alias for caches.branch.
    #     caches.branch    [String]  Filters caches by the branch the cache belongs to.
    #     caches.match     [String]  Filters caches by the string to match against the cache name.
    #     include          [String]  List of attributes to eager load.
    #     match            [String]  Alias for caches.match.
    #
    #     Example: GET /repo/rails%2Frails/caches
    #
    # **Delete**
    #
    # This deletes all caches for a repository.
    #
    # As with `find` it's possible to delete by branch or by regexp match of a string to the cache name.
    #
    # ```bash
    # curl -X DELETE \
    #   -H "Content-Type: application/json" \
    #   -H "Travis-API-Version: 3" \
    #   -H "Authorization: token xxxxxxxxxxxx" \
    #   https://api.travis-ci.com/repo/1234/caches?branch=master
    # ```
    #
    # DELETE <code>/repo/{repository.id}/caches</code>
    #
    #     Template Variable  Type     Description
    #     repository.id      Integer  Value uniquely identifying the repository.
    #
    #     Example: DELETE /repo/891/caches
    #
    # DELETE <code>/repo/{repository.slug}/caches</code>
    #
    #     Template Variable  Type    Description
    #     repository.slug    String  Same as {repository.owner.name}/{repository.name}.
    #
    #     Example: DELETE /repo/rails%2Frails/caches
    #
    # @note DELETE requests require an authorization token set in the headers. See: {authorization=}
    #
    # @param delete [Boolean] option for deleting cache(s)
    # @return [Success, RequestError]
    def caches(delete = false)
      if delete
        without_limit { delete("#{with_repo}/caches#{opts}") }
      else
        get("#{with_repo}/caches")
      end
    end

    # A list of environment variables.
    #
    # **If querying using the repository slug, it must be formatted using {http://www.w3schools.com/tags/ref_urlencode.asp standard URL encoding}, including any special characters.**
    #
    # ## Attributes
    #
    #     Name      Type       Description
    #     env_vars  [Env var]  List of env_vars.
    #
    # ## Actions
    #
    # **For Repository**
    #
    # This returns a list of environment variables for an individual repository. It is possible to use the repository id or slug in the request.
    #
    # GET <code>/repo/{repository.id}/env_vars</code>
    #
    #     Template Variable  Type     Description
    #     repository.id      Integer  Value uniquely identifying the repository.
    #     Query Parameter  Type      Description
    #     include          [String]  List of attributes to eager load.
    #
    #     Example: GET /repo/891/env_vars
    #
    # GET <code>/repo/{repository.slug}/env_vars</code>
    #
    #     Template Variable  Type    Description
    #     repository.slug    String  Same as {repository.owner.name}/{repository.name}.
    #     Query Parameter  Type      Description
    #     include          [String]  List of attributes to eager load.
    #
    #     Example: GET /repo/rails%2Frails/env_vars
    #
    # **Create**
    #
    # This creates an environment variable for an individual repository. It is possible to use the repository id or slug in the request.
    #
    # Use namespaced params in the request body to pass the new environment variables:
    #
    # ```bash
    # curl -X POST \
    #   -H "Content-Type: application/json" \
    #   -H "Travis-API-Version: 3" \
    #   -H "Authorization: token xxxxxxxxxxxx" \
    #   -d '{ "env_var.name": "FOO", "env_var.value": "bar", "env_var.public": false }' \
    #   https://api.travis-ci.com/repo/1234/env_vars
    # ```
    #
    # POST <code>/repo/{repository.id}/env_vars</code>
    #
    #     Template Variable  Type     Description
    #     repository.id      Integer  Value uniquely identifying the repository.
    #     Accepted Parameter  Type     Description
    #     env_var.name        String   The environment variable name, e.g. FOO.
    #     env_var.value       String   The environment variable's value, e.g. bar.
    #     env_var.public      Boolean  Whether this environment variable should be publicly visible or not.
    #
    #     Example: POST /repo/891/env_vars
    #
    # POST <code>/repo/{repository.slug}/env_vars</code>
    #
    #     Template Variable  Type    Description
    #     repository.slug    String  Same as {repository.owner.name}/{repository.name}.
    #     Accepted Parameter  Type     Description
    #     env_var.name        String   The environment variable name, e.g. FOO.
    #     env_var.value       String   The environment variable's value, e.g. bar.
    #     env_var.public      Boolean  Whether this environment variable should be publicly visible or not.
    #
    #     Example: POST /repo/rails%2Frails/env_vars
    #
    # @note requests require an authorization token set in the headers. See: {authorization=}
    #
    # @param create [Hash] Optional argument.  A hash of the `name`, `value`, and `public` visibleness for a env var to create
    # @return [Success, RequestError]
    def env_vars(create = nil)
      if create
        validate_env_var create

        return create("#{with_repo}/env_vars", env_var_keys(create))
      end

      get("#{with_repo}/env_vars")
    end

    # A GitHub App installation.
    #
    # ## Attributes
    #
    # **Minimal Representation**
    #
    # Included when the resource is returned as part of another resource.
    #
    #     Name       Type     Description
    #     id         Integer  The installation id.
    #     github_id  Integer  The installation's id on GitHub.
    #
    # **Standard Representation**
    #
    # Included when the resource is the main response of a request, or is {https://developer.travis-ci.com/eager-loading eager loaded}.
    #
    #     Name       Type     Description
    #     id         Integer  The installation id.
    #     github_id  Integer  The installation's id on GitHub.
    #     owner      Owner    GitHub user or organization the installation belongs to.
    #
    # ## Actions
    #
    # **Find**
    #
    # This returns a single installation.
    #
    # GET <code>/installation/{installation.github_id}</code>
    #
    #     Template Variable       Type     Description
    #     installation.github_id  Integer  The installation's id on GitHub.
    #     Query Parameter  Type      Description
    #     include          [String]  List of attributes to eager load.
    #
    # @param installation_id [String, Integer] GitHub App installation id
    # @return [Success, RequestError]
    def installation(installation_id)
      validate_number installation_id

      get("#{without_repo}/installation/#{installation_id}")
    end

    # An individual job.
    #
    # ## Attributes
    #
    # **Minimal Representation**
    #
    # Included when the resource is returned as part of another resource.
    #
    #     Name  Type     Description
    #     id    Integer  Value uniquely identifying the job.
    #
    # **Standard Representation**
    #
    # Included when the resource is the main response of a request, or is eager loaded.
    #
    #     Name           Type        Description
    #     id             Integer     Value uniquely identifying the job.
    #     allow_failure  Unknown     The job's allow_failure.
    #     number         String      Incremental number for a repository's builds.
    #     state          String      Current state of the job.
    #     started_at     String      When the job started.
    #     finished_at    String      When the job finished.
    #     build          Build       The build the job is associated with.
    #     queue          String      Worker queue this job is/was scheduled on.
    #     repository     Repository  GitHub user or organization the job belongs to.
    #     commit         Commit      The commit the job is associated with.
    #     owner          Owner       GitHub user or organization the job belongs to.
    #     stage          [Stage]     The stages of a job.
    #     created_at     String      When the job was created.
    #     updated_at     String      When the job was updated.
    #
    # ## Actions
    #
    # **Find**
    #
    # This returns a single job.
    #
    # GET <code>/job/{job.id}</code>
    #
    #     Template Variable  Type     Description
    #     job.id             Integer  Value uniquely identifying the job.
    #
    #     Query Parameter  Type      Description
    #     include          [String]  List of attributes to eager load.
    #
    #     Example: GET /job/86601347
    #
    # **Cancel**
    #
    # This cancels a currently running job.
    #
    # POST <code>/job/{job.id}/cancel</code>
    #
    #     Template Variable  Type     Description
    #     job.id             Integer  Value uniquely identifying the job.
    #
    #     Example: POST /job/86601347/cancel
    #
    # **Restart**
    #
    # This restarts a job that has completed or been canceled.
    #
    # POST <code>/job/{job.id}/restart</code>
    #
    #     Template Variable  Type     Description
    #     job.id             Integer  Value uniquely identifying the job.
    #
    #     Example: POST /job/86601347/restart
    #
    # **Debug**
    #
    # This restarts a job in debug mode, enabling the logged-in user to ssh into the build VM. Please note this feature is only available on the travis-ci.com domain, and those repositories on the travis-ci.org domain for which the debug feature is enabled. See this document for more details.
    #
    # POST <code>/job/{job.id}/debug</code>
    #
    #     Template Variable  Type     Description
    #     job.id             Integer  Value uniquely identifying the job.
    #
    #     Example: POST /job/86601347/debug
    #
    # @note POST requests require an authorization token set in the headers. See: {authorization=}
    #
    # @param job_id [String, Integer] the job id number
    # @param option [Symbol] options for :cancel, :restart, or :debug
    # @return [Success, RequestError]
    def job(job_id, option = nil)
      case option
      when :cancel
        post("#{without_repo}/job/#{job_id}/cancel")
      when :restart
        post("#{without_repo}/job/#{job_id}/restart")
      when :debug
        post("#{without_repo}/job/#{job_id}/debug")
      else
        get("#{without_repo}/job/#{job_id}")
      end
    end

    # Users may add a public/private RSA key pair to a repository.
    # This can be used within builds, for example to access third-party services or deploy code to production.
    # Please note this feature is only available on the travis-ci.com domain.
    #
    # ## Attributes
    #
    # **Standard Representation**
    #
    # Included when the resource is the main response of a request, or is {https://developer.travis-ci.com/eager-loading eager loaded}.
    #
    #     Name         Type    Description
    #     description  String  A text description.
    #     public_key   String  The public key.
    #     fingerprint  String  The fingerprint.
    #
    # **Minimal Representation**
    #
    # Included when the resource is returned as part of another resource.
    #
    #     Name         Type    Description
    #     description  String  A text description.
    #     public_key   String  The public key.
    #     fingerprint  String  The fingerprint.
    #
    # ## Actions
    #
    # **Find**
    #
    # Return the current key pair, if it exists.
    #
    # GET <code>/repo/{repository.id}/key_pair</code>
    #
    #     Template Variable  Type     Description
    #     repository.id      Integer  Value uniquely identifying the repository.
    #     Query Parameter  Type      Description
    #     include          [String]  List of attributes to eager load.
    #
    #     Example: GET /repo/891/key_pair
    #
    # GET <code>/repo/{repository.slug}/key_pair</code>
    #
    #     Template Variable  Type    Description
    #     repository.slug    String  Same as {repository.owner.name}/{repository.name}.
    #     Query Parameter  Type      Description
    #     include          [String]  List of attributes to eager load.
    #
    #     Example: GET /repo/rails%2Frails/key_pair
    #
    # **Create**
    #
    # Creates a new key pair.
    #
    # ```bash
    # curl -X POST \
    #   -H "Content-Type: application/json" \
    #   -H "Travis-API-Version: 3" \
    #   -H "Authorization: token xxxxxxxxxxxx" \
    #   -d '{ "key_pair.description": "FooBar", "key_pair.value": "xxxxx"}' \
    #   https://api.travis-ci.com/repo/1234/key_pair
    # ```
    #
    # POST <code>/repo/{repository.id}/key_pair</code>
    #
    #     Template Variable  Type     Description
    #     repository.id      Integer  Value uniquely identifying the repository.
    #     Accepted Parameter    Type    Description
    #     key_pair.description  String  A text description.
    #     key_pair.value        String  The private key.
    #
    #     Example: POST /repo/891/key_pair
    #
    # POST <code>/repo/{repository.slug}/key_pair</code>
    #
    #     Template Variable  Type    Description
    #     repository.slug    String  Same as {repository.owner.name}/{repository.name}.
    #     Accepted Parameter    Type    Description
    #     key_pair.description  String  A text description.
    #     key_pair.value        String  The private key.
    #
    #     Example: POST /repo/rails%2Frails/key_pair
    #
    # **Update**
    #
    # Update the key pair.
    #
    # ```bash
    # curl -X PATCH \
    #   -H "Content-Type: application/json" \
    #   -H "Travis-API-Version: 3" \
    #   -H "Authorization: token xxxxxxxxxxxx" \
    #   -d '{ "key_pair.description": "FooBarBaz" }' \
    #   https://api.travis-ci.com/repo/1234/key_pair
    # ```
    #
    # PATCH <code>/repo/{repository.id}/key_pair</code>
    #
    #     Template Variable  Type     Description
    #     repository.id      Integer  Value uniquely identifying the repository.
    #     Accepted Parameter    Type    Description
    #     key_pair.description  String  A text description.
    #     key_pair.value        String  The private key.
    #
    #     Example: PATCH /repo/891/key_pair
    #
    # PATCH <code>/repo/{repository.slug}/key_pair</code>
    #
    #     Template Variable  Type    Description
    #     repository.slug    String  Same as {repository.owner.name}/{repository.name}.
    #     Accepted Parameter    Type    Description
    #     key_pair.description  String  A text description.
    #     key_pair.value        String  The private key.
    #
    #     Example: PATCH /repo/rails%2Frails/key_pair
    #
    # **Delete**
    #
    # Delete the key pair.
    #
    # DELETE <code>/repo/{repository.id}/key_pair</code>
    #
    #     Template Variable  Type     Description
    #     repository.id      Integer  Value uniquely identifying the repository.
    #
    #     Example: DELETE /repo/891/key_pair
    #
    # DELETE <code>/repo/{repository.slug}/key_pair</code>
    #
    #     Template Variable  Type    Description
    #     repository.slug    String  Same as {repository.owner.name}/{repository.name}.
    #
    #     Example: DELETE /repo/rails%2Frails/key_pair
    #
    # @note requests require an authorization token set in the headers. See: {authorization=}
    # @note API enpoint needs to be set to `https://api.travis-ci.com` See: {api_endpoint=}
    #
    # @overload key_par()
    #   Gets current key_pair if any
    # @overload key_pair(action: params)
    #   Performs action per specific key word argument
    #   @param create [Hash] Create a new key pair from provided private key { description: "name", value: "private key" }
    #   @param update [Hash] Update key pair with hash { description: "new name" }
    #   @param delete [Boolean] Use truthy value to delete current key pair
    # @return [Success, RequestError]
    def key_pair(create: nil, update: nil, delete: nil)
      raise 'Too many options specified' unless [create, update, delete].compact.count < 2

      create and return create("#{with_repo}/key_pair", key_pair_keys(create))
      update and return patch("#{with_repo}/key_pair", key_pair_keys(update))
      delete and return delete("#{with_repo}/key_pair")
      get("#{with_repo}/key_pair")
    end

    # Every repository has an auto-generated RSA key pair. This is used when cloning the repository from GitHub and when encrypting/decrypting secure data for use in builds, e.g. via the Travis CI command line client.
    #
    # Users may read the public key and fingerprint via GET request, or generate a new key pair via POST, but otherwise this key pair cannot be edited or removed.
    #
    # ## Attributes
    #
    # **Standard Representation**
    #
    # Included when the resource is the main response of a request, or is {https://developer.travis-ci.com/eager-loading eager loaded}.
    #
    #     Name         Type    Description
    #     description  String  A text description.
    #     public_key   String  The public key.
    #     fingerprint  String  The fingerprint.
    #
    # **Minimal Representation**
    #
    # Included when the resource is returned as part of another resource.
    #
    #     Name         Type    Description
    #     description  String  A text description.
    #     public_key   String  The public key.
    #     fingerprint  String  The fingerprint.
    #
    # ## Actions
    #
    # **Find**
    #
    # Return the current key pair.
    #
    # GET <code>/repo/{repository.id}/key_pair/generated</code>
    #
    #     Template Variable  Type     Description
    #     repository.id      Integer  Value uniquely identifying the repository.
    #     Query Parameter  Type      Description
    #     include          [String]  List of attributes to eager load.
    #
    #     Example: GET /repo/891/key_pair/generated
    #
    # GET <code>/repo/{repository.slug}/key_pair/generated</code>
    #
    #     Template Variable  Type    Description
    #     repository.slug    String  Same as {repository.owner.name}/{repository.name}.
    #     Query Parameter  Type      Description
    #     include          [String]  List of attributes to eager load.
    #
    #     Example: GET /repo/rails%2Frails/key_pair/generated
    #
    # **Create**
    #
    # Generate a new key pair, replacing the previous one.
    #
    # POST <code>/repo/{repository.id}/key_pair/generated</code>
    #
    #     Template Variable  Type     Description
    #     repository.id      Integer  Value uniquely identifying the repository.
    #
    #     Example: POST /repo/891/key_pair/generated
    #
    # POST <code>/repo/{repository.slug}/key_pair/generated</code>
    #
    #     Template Variable  Type    Description
    #     repository.slug    String  Same as {repository.owner.name}/{repository.name}.
    #
    #     Example: POST /repo/rails%2Frails/key_pair/generated
    #
    # @note requests require an authorization token set in the headers. See: {authorization=}
    #
    # @param action [String, Symbol] defaults to getting current key pair, use `:create` if you would like to generate a new key pair
    # @return [Success, RequestError]
    def key_pair_generated(action = :get)
      return post("#{with_repo}/key_pair/generated") if action.match?(/create/i)

      get("#{with_repo}/key_pair/generated")
    end

    # This validates the `.travis.yml` file and returns any warnings.
    #
    # The request body can contain the content of the .travis.yml file directly as a string, eg "foo: bar".
    #
    # ## Attributes
    #
    #     Name      Type   Description
    #     warnings  Array  An array of hashes with keys and warnings.
    #
    # ## Actions
    #
    # **Lint**
    #
    # POST <code>/lint</code>
    #
    #     Example: POST /lint
    #
    # @param yaml_content [String] the contents for the file `.travis.yml`
    # @return [Success, RequestError]
    def lint(yaml_content)
      validate_string yaml_content

      ct = headers.remove(:'Content-Type')
      result = post("#{without_repo}/lint", yaml_content)
      h('Content-Type': ct) if ct
      result
    end

    # An individual log.
    #
    # ## Attributes
    #
    # **Minimal Representation**
    #
    # Included when the resource is returned as part of another resource.
    #
    #     Name  Type     Description
    #     id    Unknown  The log's id.
    #
    # **Standard Representation**
    #
    # Included when the resource is the main response of a request, or is eager loaded.
    #
    #     Name       Type     Description
    #     id         Unknown  The log's id.
    #     content    Unknown  The log's content.
    #     log_parts  Unknown  The log's log_parts.
    #
    # ## Actions
    #
    # **Find**
    #
    # This returns a single log.
    #
    # It's possible to specify the accept format of the request as text/plain if required. This will return the content of the log as a single blob of text.
    #
    #     curl -H "Travis-API-Version: 3" \
    #       -H "Accept: text/plain" \
    #       -H "Authorization: token xxxxxxxxxxxx" \
    #       https://api.travis-ci.org/job/{job.id}/log
    #
    # The default response type is application/json, and will include additional meta data such as @type, @representation etc. (see [https://developer.travis-ci.org/format](https://developer.travis-ci.org/format)).
    #
    # GET <code>/job/{job.id}/log</code>
    #
    #     Template Variable  Type     Description
    #     job.id             Integer  Value uniquely identifying the job.
    #
    #     Query Parameter  Type      Description
    #     include          [String]  List of attributes to eager load.
    #     log.token        Unknown   Documentation missing.
    #
    #     Example: GET /job/86601347/log
    #
    # GET <code>/job/{job.id}/log.txt</code>
    #
    #     Template Variable  Type     Description
    #     job.id             Integer  Value uniquely identifying the job.
    #
    #     Query Parameter  Type      Description
    #     include          [String]  List of attributes to eager load.
    #     log.token        Unknown   Documentation missing.
    #
    #     Example: GET /job/86601347/log.txt
    #
    # **Delete**
    #
    # This removes the contents of a log. It gets replace with the message: Log removed by XXX at 2017-02-13 16:00:00 UTC.
    #
    #     curl -X DELETE \
    #       -H "Travis-API-Version: 3" \
    #       -H "Authorization: token xxxxxxxxxxxx" \
    #       https://api.travis-ci.org/job/{job.id}/log
    #
    # DELETE <code>/job/{job.id}/log</code>
    #
    #     Template Variable  Type     Description
    #     job.id             Integer  Value uniquely identifying the job.
    #
    #     Example: DELETE /job/86601347/log
    #
    # @note DELETE is unimplemented
    #
    # @param job_id [String, Integer] the job id number
    # @param option [Symbol] options for :text or :delete
    # @return [Success, String, RequestError]
    def log(job_id, option = nil)
      case option
      when :text
        get("#{without_repo}/job/#{job_id}/log.txt", true)
      when :delete
        raise Unimplemented
      else
        get("#{without_repo}/job/#{job_id}/log")
      end
    end

    # A list of messages. Messages belong to resource types.
    #
    # ## Attributes
    #
    #     Name      Type       Description
    #     messages  [Message]  List of messages.
    #
    # **Collection Items**
    #
    # Each entry in the messages array has the following attributes:
    #
    #     Name   Type     Description
    #     id     Integer  The message's id.
    #     level  String   The message's level.
    #     key    String   The message's key.
    #     code   String   The message's code.
    #     args   Json     The message's args.
    #
    # ## Actions
    #
    # **For Request**
    #
    # This will return a list of messages created by `travis-yml` for a request, if any exist.
    #
    # GET <code>/repo/{repository.id}/request/{request.id}/messages</code>
    #
    #     Template Variable  Type     Description
    #     repository.id      Integer  Value uniquely identifying the repository.
    #     request.id         Integer  Value uniquely identifying the request.
    #     Query Parameter  Type      Description
    #     include          [String]  List of attributes to eager load.
    #     limit            Integer   How many messages to include in the response. Used for pagination.
    #     offset           Integer   How many messages to skip before the first entry in the response. Used for pagination.
    #
    # GET <code>/repo/{repository.slug}/request/{request.id}/messages</code>
    #
    #     Template Variable  Type     Description
    #     repository.slug    String   Same as {repository.owner.name}/{repository.name}.
    #     request.id         Integer  Value uniquely identifying the request.
    #     Query Parameter  Type      Description
    #     include          [String]  List of attributes to eager load.
    #     limit            Integer   How many messages to include in the response. Used for pagination.
    #     offset           Integer   How many messages to skip before the first entry in the response. Used for pagination.
    #
    # @param request_id [String, Integer] the request id
    # @return [Success, RequestError]
    def messages(request_id)
      validate_number request_id

      get("#{with_repo}/request/#{request_id}/messages")
    end

    # An individual organization.
    #
    # ## Attributes
    #
    # **Minimal Representation**
    #
    # Included when the resource is returned as part of another resource.
    #
    #     Name   Type     Description
    #     id     Integer  Value uniquely identifying the organization.
    #     login  String   Login set on GitHub.
    #
    # **Standard Representation**
    #
    # Included when the resource is the main response of a request, or is {https://developer.travis-ci.com/eager-loading eager loaded}.
    #
    #     Name             Type     Description
    #     id               Integer  Value uniquely identifying the organization.
    #     login            String   Login set on GitHub.
    #     name             String   Name set on GitHub.
    #     github_id        Integer  Id set on GitHub.
    #     avatar_url       String   Avatar_url set on GitHub.
    #     education        Boolean  Whether or not the organization has an education account.
    #     allow_migration  Unknown  The organization's allow_migration.
    #
    # **Additional Attributes**
    #
    #     Name          Type          Description
    #     repositories  [Repository]  Repositories belonging to this organization.
    #     installation  Installation  Installation belonging to the organization.
    #
    # ## Actions
    #
    # **Find**
    #
    # This returns an individual organization.
    #
    # GET <code>/org/{organization.id}</code>
    #
    #     Template Variable  Type      Description
    #     organization.id    Integer   Value uniquely identifying the organization.
    #     Query Parameter    Type      Description
    #     include            [String]  List of attributes to eager load.
    #
    #     Example: GET /org/87
    #
    # @param org_id [String, Integer] the organization id
    # @raise [TypeError] if given organization id is not a number
    # @return [Success, RequestError]
    def organization(org_id)
      validate_number org_id

      get("#{without_repo}/org/#{org_id}")
    end

    # A list of organizations for the current user.
    #
    # ## Attributes
    #
    #     Name           Type            Description
    #     organizations  [Organization]  List of organizations.
    #
    # **Collection Items**
    #
    # Each entry in the **organizations** array has the following attributes:
    #
    #     Name             Type          Description
    #     id               Integer       Value uniquely identifying the organization.
    #     login            String        Login set on GitHub.
    #     name             String        Name set on GitHub.
    #     github_id        Integer       Id set on GitHub.
    #     avatar_url       String        Avatar_url set on GitHub.
    #     education        Boolean       Whether or not the organization has an education account.
    #     allow_migration  Unknown       The organization's allow_migration.
    #     repositories     [Repository]  Repositories belonging to this organization.
    #     installation     Installation  Installation belonging to the organization.
    #
    # ## Actions
    #
    # **For Current User**
    #
    # This returns a list of organizations the current user is a member of.
    #
    # GET <code>/orgs</code>
    #
    #     Query Parameter    Type      Description
    #     include            [String]  List of attributes to eager load.
    #     limit              Integer   How many organizations to include in the response. Used for pagination.
    #     offset             Integer   How many organizations to skip before the first entry in the response. Used for pagination.
    #     organization.role  Unknown   Documentation missing.
    #     role               Unknown   Alias for organization.role.
    #     sort_by            [String]  Attributes to sort organizations by. Used for pagination.
    #
    #     Example: GET /orgs?limit=5
    #
    # **Sortable by:** <code>id</code>, <code>login</code>, <code>name</code>, <code>github_id</code>, append <code>:desc</code> to any attribute to reverse order.
    #
    # @return [Success, RequestError]
    def organizations
      get("#{without_repo}/orgs")
    end

    # This will be either a {https://developer.travis-ci.com/resource/user user} or {https://developer.travis-ci.com/resource/organization organization}.
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
    # Included when the resource is the main response of a request, or is {https://developer.travis-ci.com/eager-loading eager loaded}.
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
    #     user.login         String    Login set on GitHub.
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
    # @param owner [String] username or github id
    # @return [Success, RequestError]
    def owner(owner = username)
      if number? owner
        get("#{without_repo}/owner/github_id/#{owner}")
      else
        get("#{without_repo}/owner/#{owner}")
      end
    end

    # Document `resources/preference/overview` not found.
    #
    # ## Attributes
    #
    # **Standard Representation**
    #
    # Included when the resource is the main response of a request, or is {https://developer.travis-ci.com/eager-loading eager loaded}.
    #
    #     Name   Type     Description
    #     name   Unknown  The preference's name.
    #     value  Unknown  The preference's value.
    #
    # **Minimal Representation**
    #
    # Included when the resource is returned as part of another resource.
    #
    #     Name   Type     Description
    #     name   Unknown  The preference's name.
    #     value  Unknown  The preference's value.
    #
    # ## Actions
    #
    # **For Organization**
    #
    # Document `resources/preference/actions/for_organization` not found.
    #
    # GET <code>/org/{organization.id}/preference/{preference.name}</code>
    #
    #     Template Variable  Type     Description
    #     organization.id    Integer  Value uniquely identifying the organization.
    #     preference.name    Unknown  The preference's name.
    #     Query Parameter  Type      Description
    #     include          [String]  List of attributes to eager load.
    #
    # **Update**
    #
    # Document `resources/preference/actions/update` not found.
    #
    # PATCH <code>/org/{organization.id}/preference/{preference.name}</code>
    #
    #     Template Variable  Type     Description
    #     organization.id    Integer  Value uniquely identifying the organization.
    #     preference.name    Unknown  The preference's name.
    #     Accepted Parameter  Type     Description
    #     preference.value    Unknown  The preference's value.
    #
    # PATCH <code>/preference/{preference.name}</code>
    #
    #     Template Variable  Type     Description
    #     preference.name    Unknown  The preference's name.
    #     Accepted Parameter  Type     Description
    #     preference.value    Unknown  The preference's value.
    #
    # **Find**
    #
    # Document `resources/preference/actions/find` not found.
    #
    # GET <code>/preference/{preference.name}</code>
    #
    #     Template Variable  Type     Description
    #     preference.name    Unknown  The preference's name.
    #     Query Parameter  Type      Description
    #     include          [String]  List of attributes to eager load.
    #
    # @note requests require an authorization token set in the headers. See: {authorization=}
    #
    # @param key [String] preference name to get or set
    # @param value [String] optional value to set preference
    # @param org_id [String, Integer] optional keyword argument for an organization id
    # @return [Success, RequestError]
    def preference(key, value = nil, org_id: nil)
      if org_id
        validate_number org_id
        org_id = "/org/#{org_id}"
      end

      if value.nil?
        get("#{without_repo}#{org_id}/preference/#{key}")
      else
        patch("#{without_repo}#{org_id}/preference/#{key}", 'preference.value' => value)
      end
    end

    # Document `resources/preferences/overview` not found.
    #
    # ## Attributes
    #
    #     Name         Type         Description
    #     preferences  [Preferenc]  List of preferences.
    #
    # ## Actions
    #
    # **For Organization**
    #
    # Document `resources/preferences/actions/for_organization` not found.
    #
    # GET <code>/org/{organization.id}/preferences</code>
    #
    #     Template Variable  Type     Description
    #     organization.id    Integer  Value uniquely identifying the organization.
    #     Query Parameter  Type      Description
    #     include          [String]  List of attributes to eager load.
    #
    #     Example: GET /org/87/preferences
    #
    # **For User**
    #
    # Document `resources/preferences/actions/for_user` not found.
    #
    # GET <code>/preferences</code>
    #
    #     Query Parameter  Type      Description
    #     include          [String]  List of attributes to eager load.
    #
    #     Example: GET /preferences
    #
    # @note requests require an authorization token set in the headers. See: {authorization=}
    #
    # @param org_id [String, Integer] optional organization id
    # @return [Success, RequestError]
    def preferences(org_id = nil)
      if org_id
        validate_number org_id
        org_id = "/org/#{org_id}"
      end

      get("#{without_repo}#{org_id}/preferences")
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
    # **Sortable by:** <code>id</code>, <code>github_id</code>, <code>owner_name</code>, <code>name</code>, <code>active</code>, <code>default_branch.last_build</code>, append <code>:desc</code> to any attribute to reverse order.
    #
    # GET <code>/owner/{user.login}/repos</code>
    #
    #     Template Variable  Type    Description
    #     user.login         String  Login set on GitHub.
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
    # **Sortable by:** <code>id</code>, <code>github_id</code>, <code>owner_name</code>, <code>name</code>, <code>active</code>, <code>default_branch.last_build</code>, append <code>:desc</code> to any attribute to reverse order.
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
    # **Sortable by:** <code>id</code>, <code>github_id</code>, <code>owner_name</code>, <code>name</code>, <code>active</code>, <code>default_branch.last_build</code>, append <code>:desc</code> to any attribute to reverse order.
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
    # **Sortable by:** <code>id</code>, <code>github_id</code>, <code>owner_name</code>, <code>name</code>, <code>active</code>, <code>default_branch.last_build</code>, append <code>:desc</code> to any attribute to reverse order.
    #
    # **For Current User**
    #
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
    # **Sortable by:** <code>id</code>, <code>github_id</code>, <code>owner_name</code>, <code>name</code>, <code>active</code>, <code>default_branch.last_build</code>, append <code>:desc</code> to any attribute to reverse order.
    #
    # @param owner [String] username or github id
    # @return [Success, RequestError]
    def repositories(owner = username)
      if number? owner
        get("#{without_repo}/owner/github_id/#{owner}/repos#{opts}")
      else
        get("#{without_repo}/owner/#{owner}/repos#{opts}")
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
    # @note POST requests require an authorization token set in the headers. See: {authorization=}
    #
    # @param repo [String] github_username/repository_name
    # @param action [String, Symbol] Optional argument for star/unstar/activate/deactivate
    # @raise [InvalidRepository] if given input does not
    #   conform to valid repository identifier format
    # @return [Success, RequestError]
    def repository(repo = repository_name, action = nil)
      validate_repo_format repo

      repo = sanitize_repo_name repo
      action = '' unless %w[star unstar activate deactivate].include? action.to_s

      if action.empty?
        get("#{without_repo}/repo/#{repo}")
      else
        post("#{without_repo}/repo/#{repo}/#{action}")
      end
    end

    # An individual request
    #
    # ## Attributes
    #
    # **Minimal Representation**
    #
    # Included when the resource is returned as part of another resource.
    #
    #     Name     Type     Description
    #     id       Integer  Value uniquely identifying the request.
    #     state    String   The state of a request (eg. whether it has been processed or not).
    #     result   String   The result of the request (eg. rejected or approved).
    #     message  String   Travis-ci status message attached to the request.
    #
    # **Standard Representation**
    #
    # Included when the resource is the main response of a request, or is {https://developer.travis-ci.com/eager-loading eager loaded}.
    #
    #     Name         Type        Description
    #     id           Integer     Value uniquely identifying the request.
    #     state        String      The state of a request (eg. whether it has been processed or not).
    #     result       String      The result of the request (eg. rejected or approved).
    #     message      String      Travis-ci status message attached to the request.
    #     repository   Repository  GitHub user or organization the request belongs to.
    #     branch_name  String      Name of the branch requested to be built.
    #     commit       Commit      The commit the request is associated with.
    #     builds       [Build]     The request's builds.
    #     owner        Owner       GitHub user or organization the request belongs to.
    #     created_at   String      When Travis CI created the request.
    #     event_type   String      Origin of request (push, pull request, api).
    #     base_commit  String      The base commit the request is associated with.
    #     head_commit  String      The head commit the request is associated with.
    #
    # ## Actions
    #
    # **Find**
    #
    # Document `resources/request/actions/find` not found.
    #
    # GET <code>/repo/{repository.id}/request/{request.id}</code>
    #
    #     Template Variable  Type     Description
    #     repository.id      Integer  Value uniquely identifying the repository.
    #     request.id         Integer  Value uniquely identifying the request.
    #     Query Parameter  Type      Description
    #     include          [String]  List of attributes to eager load.
    #
    # GET <code>/repo/{repository.slug}/request/{request.id}</code>
    #
    #     Template Variable  Type     Description
    #     repository.slug    String   Same as {repository.owner.name}/{repository.name}.
    #     request.id         Integer  Value uniquely identifying the request.
    #     Query Parameter  Type      Description
    #     include          [String]  List of attributes to eager load.
    #
    # @param request_id [String, Integer] request id
    # @return [Success, RequestError]
    def request(request_id)
      validate_number request_id

      get("#{with_repo}/request/#{request_id}")
    end

    # A list of requests.
    #
    # If querying using the repository slug, it must be formatted using {http://www.w3schools.com/tags/ref_urlencode.asp standard URL encoding}, including any special characters.
    #
    # ## Attributes
    #
    #     Name      Type       Description
    #     requests  [Request]  List of requests.
    #
    # **Collection Items**
    #
    # Each entry in the **requests** array has the following attributes:
    #
    #     Name         Type        Description
    #     id           Integer     Value uniquely identifying the request.
    #     state        String      The state of a request (eg. whether it has been processed or not).
    #     result       String      The result of the request (eg. rejected or approved).
    #     message      String      Travis-ci status message attached to the request.
    #     repository   Repository  GitHub user or organization the request belongs to.
    #     branch_name  String      Name of the branch requested to be built.
    #     commit       Commit      The commit the request is associated with.
    #     builds       [Build]     The request's builds.
    #     owner        Owner       GitHub user or organization the request belongs to.
    #     created_at   String      When Travis CI created the request.
    #     event_type   String      Origin of request (push, pull request, api).
    #     base_commit  String      The base commit the request is associated with.
    #     head_commit  String      The head commit the request is associated with.
    #     yaml_config  Unknown     The request's yaml_config.
    #
    # ## Actions
    #
    # **Find**
    #
    # This will return a list of requests belonging to a repository.
    #
    # GET <code>/repo/{repository.id}/requests</code>
    #
    #     Template Variable  Type     Description
    #     repository.id      Integer  Value uniquely identifying the repository.
    #     Query Parameter  Type      Description
    #     include          [String]  List of attributes to eager load.
    #     limit            Integer   How many requests to include in the response. Used for pagination.
    #     offset           Integer   How many requests to skip before the first entry in the response. Used for pagination.
    #
    #     Example: GET /repo/891/requests?limit=5
    #
    # GET <code>/repo/{repository.slug}/requests</code>
    #
    #     Template Variable  Type    Description
    #     repository.slug    String  Same as {repository.owner.name}/{repository.name}.
    #     Query Parameter  Type      Description
    #     include          [String]  List of attributes to eager load.
    #     limit            Integer   How many requests to include in the response. Used for pagination.
    #     offset           Integer   How many requests to skip before the first entry in the response. Used for pagination.
    #
    #     Example: GET /repo/rails%2Frails/requests?limit=5
    #
    # **Create**
    #
    # This will create a request for an individual repository, triggering a build to run on Travis CI.
    #
    # Use namespaced params in JSON format in the request body to pass any accepted parameters. Any keys in the request's config will override keys existing in the `.travis.yml`.
    #
    # ```bash
    # curl -X POST \
    #   -H "Content-Type: application/json" \
    #   -H "Travis-API-Version: 3" \
    #   -H "Authorization: token xxxxxxxxxxxx" \
    #   -d '{ "request": {
    #         "message": "Override the commit message: this is an api request", "branch": "master" }}'\
    #   https://api.travis-ci.com/repo/1/requests
    # ```
    #
    # The response includes the following body:
    #
    # ```json
    # {
    #   "@type":              "pending",
    #   "remaining_requests": 1,
    #   "repository":         {
    #     "@type":            "repository",
    #     "@href":            "/repo/1",
    #     "@representation":  "minimal",
    #     "id":               1,
    #     "name":             "test",
    #     "slug":             "owner/repo"
    #   },
    #   "request":            {
    #     "repository":       {
    #       "id":             1,
    #       "owner_name":     "owner",
    #       "name":           "repo"
    #     },
    #     "user":             {
    #       "id":             1
    #     },
    #     "id":               1,
    #     "message":          "Override the commit message: this is an api request",
    #     "branch":           "master",
    #     "config":           { }
    #   },
    #   "resource_type":      "request"
    # }
    # ```
    #
    # POST <code>/repo/{repository.id}/requests</code>
    #
    #     Template Variable  Type     Description
    #     repository.id      Integer  Value uniquely identifying the repository.
    #     Accepted Parameter  Type    Description
    #     request.config      String  Build configuration (as parsed from .travis.yml).
    #     request.message     String  Travis-ci status message attached to the request.
    #     request.branch      String  Branch requested to be built.
    #     request.token       Object  Travis token associated with webhook on GitHub (DEPRECATED).
    #
    #     Example: POST /repo/891/requests
    #
    # POST <code>/repo/{repository.slug}/requests</code>
    #
    #     Template Variable  Type    Description
    #     repository.slug    String  Same as {repository.owner.name}/{repository.name}.
    #     Accepted Parameter  Type    Description
    #     request.config      String  Build configuration (as parsed from .travis.yml).
    #     request.message     String  Travis-ci status message attached to the request.
    #     request.branch      String  Branch requested to be built.
    #     request.token       Object  Travis token associated with webhook on GitHub (DEPRECATED).
    #
    #     Example: POST /repo/rails%2Frails/requests
    #
    # @param attributes [Hash] request attributes
    # @return [Success, RequestError]
    def requests(**attributes)
      return get("#{with_repo}/requests") if attributes.empty?

      create("#{with_repo}/requests", 'request': attributes)
    end

    # A list of stages.
    #
    # Currently this is nested within a build.
    #
    # ## Attributes
    #
    #     Name    Type     Description
    #     stages  [Stage]  List of stages.
    #
    # **Collection Items**
    #
    # Each entry in the stages array has the following attributes:
    #
    #     Name         Type     Description
    #     id           Integer  Value uniquely identifying the stage.
    #     number       Integer  Incremental number for a stage.
    #     name         String   The name of the stage.
    #     state        String   Current state of the stage.
    #     started_at   String   When the stage started.
    #     finished_at  String   When the stage finished.
    #     jobs         [Job]    The jobs of a stage.
    #
    # ## Actions
    #
    # **Find**
    #
    # This returns a list of stages belonging to an individual build.
    #
    # GET <code>/build/{build.id}/stages</code>
    #
    #     Template Variable  Type     Description
    #     build.id           Integer  Value uniquely identifying the build.
    #     Query Parameter  Type      Description
    #     include          [String]  List of attributes to eager load.
    #
    #     Example: GET /build/86601346/stages
    #
    # @param build_id [String, Integer] build id
    # @raise [TypeError] if given build id is not a number
    # @return [Success, RequestError]
    def stages(build_id)
      validate_number build_id

      get("#{without_repo}/build/#{build_id}/stages")
    end

    # An individual repository setting. These are settings on a repository that can be adjusted by the user. There are currently five different kinds of settings a user can modify:
    #
    # * `builds_only_with_travis_yml` (boolean)
    # * `build_pushes` (boolean)
    # * `build_pull_requests` (boolean)
    # * `maximum_number_of_builds` (integer)
    # * `auto_cancel_pushes` (boolean)
    # * `auto_cancel_pull_requests` (boolean)
    #
    # If querying using the repository slug, it must be formatted using {http://www.w3schools.com/tags/ref_urlencode.asp standard URL encoding}, including any special characters.
    #
    # ## Attributes
    #
    # **Standard Representation**
    #
    # Included when the resource is the main response of a request, or is {https://developer.travis-ci.com/eager-loading eager loaded}.
    #
    #     Name   Type                Description
    #     name   String              The setting's name.
    #     value  Boolean or integer  The setting's value.
    #
    # **Minimal Representation**
    #
    # Included when the resource is returned as part of another resource.
    #
    #   Name   Type                Description
    #   name   String              The setting's name.
    #   value  Boolean or integer  The setting's value.
    #
    # ## Actions
    #
    # **Find**
    #
    # This returns a single setting. It is possible to use the repository id or slug in the request.
    #
    # GET <code>/repo/{repository.id}/setting/{setting.name}</code>
    #
    #     Template Variable  Type     Description
    #     repository.id      Integer  Value uniquely identifying the repository.
    #     setting.name       String   The setting's name.
    #     Query Parameter  Type      Description
    #     include          [String]  List of attributes to eager load.
    #
    # GET <code>/repo/{repository.slug}/setting/{setting.name}</code>
    #
    #     Template Variable  Type    Description
    #     repository.slug    String  Same as {repository.owner.name}/{repository.name}.
    #     setting.name       String  The setting's name.
    #     Query Parameter  Type      Description
    #     include          [String]  List of attributes to eager load.
    #
    # **Update**
    #
    # This updates a single setting. It is possible to use the repository id or slug in the request.
    #
    # Use namespaced params in the request body to pass the new setting:
    #
    # ```bash
    # curl -X PATCH \
    #   -H "Content-Type: application/json" \
    #   -H "Travis-API-Version: 3" \
    #   -H "Authorization: token xxxxxxxxxxxx" \
    #   -d '{ "setting.value": true }' \
    #   https://api.travis-ci.com/repo/1234/setting/{setting.name}
    # ```
    #
    # PATCH <code>/repo/{repository.id}/setting/{setting.name}</code>
    #
    #     Template Variable  Type     Description
    #     repository.id      Integer  Value uniquely identifying the repository.
    #     setting.name       String   The setting's name.
    #     Accepted Parameter  Type                Description
    #     setting.value       Boolean or integer  The setting's value.
    #
    # PATCH <code>/repo/{repository.slug}/setting/{setting.name}</code>
    #
    #     Template Variable  Type    Description
    #     repository.slug    String  Same as {repository.owner.name}/{repository.name}.
    #     setting.name       String  The setting's name.
    #     Accepted Parameter  Type                Description
    #     setting.value       Boolean or integer  The setting's value.
    #
    # @param name [String] the setting name for the current repository
    # @param value [String] optional argument for setting a value for the setting name
    # @return [Success, RequestError]
    def setting(name, value = nil)
      return get("#{with_repo}/setting/#{name}") if value.nil?

      patch("#{with_repo}/setting/#{name}", 'setting.value' => value)
    end

    # A list of user settings. These are settings on a repository that can be adjusted by the user. There are currently six different kinds of user settings:
    #
    # * `builds_only_with_travis_yml` (boolean)
    # * `build_pushes` (boolean)
    # * `build_pull_requests` (boolean)
    # * `maximum_number_of_builds` (integer)
    # * `auto_cancel_pushes` (boolean)
    # * `auto_cancel_pull_requests` (boolean)
    #
    # If querying using the repository slug, it must be formatted using {http://www.w3schools.com/tags/ref_urlencode.asp standard URL encoding}, including any special characters.
    #
    # ## Attributes
    #
    #     Name      Type       Description
    #     settings  [Setting]  List of settings.
    #
    # **Collection Items**
    #
    # Each entry in the settings array has the following attributes:
    #
    #     Name   Type                Description
    #     name   String              The setting's name.
    #     value  Boolean or integer  The setting's value.
    #
    # ## Actions
    #
    # **For Repository**
    #
    # This returns a list of the settings for that repository. It is possible to use the repository id or slug in the request.
    #
    # GET <code>/repo/{repository.id}/settings</code>
    #
    #     Template Variable  Type     Description
    #     repository.id      Integer  Value uniquely identifying the repository.
    #     Query Parameter  Type      Description
    #     include          [String]  List of attributes to eager load.
    #
    #     Example: GET /repo/891/settings
    #
    # GET <code>/repo/{repository.slug}/settings</code>
    #
    #     Template Variable  Type    Description
    #     repository.slug    String  Same as {repository.owner.name}/{repository.name}.
    #     Query Parameter  Type      Description
    #     include          [String]  List of attributes to eager load.
    #
    #     Example: GET /repo/rails%2Frails/settings
    #
    # @return [Success, RequestError]
    def settings
      get("#{with_repo}/settings")
    end

    # An individual user.
    #
    # ## Attributes
    #
    # **Minimal Representation**
    #
    # Included when the resource is returned as part of another resource.
    #
    #     Name  Type     Description
    #     id    Integer  Value uniquely identifying the user.
    #     login String   Login set on GitHub.
    #
    # **Standard Representation**
    #
    # Included when the resource is the main response of a request, or is {https://developer.travis-ci.com/eager-loading eager loaded}.
    #
    #     Name              Type     Description
    #     id                Integer  Value uniquely identifying the user.
    #     login             String   Login set on GitHub.
    #     name              String   Name set on GitHub.
    #     github_id         Integer  Id set on GitHub.
    #     avatar_url        String   Avatar URL set on GitHub.
    #     education         Boolean  Whether or not the user has an education account.
    #     allow_migration   Unknown  The user's allow_migration.
    #     is_syncing        Boolean  Whether or not the user is currently being synced with GitHub.
    #     synced_at         String   The last time the user was synced with GitHub.
    #
    # **Additional Attributes**
    #
    #     Name          Type          Description
    #     repositories  [Repository]  Repositories belonging to this user.
    #     installation  Installation  Installation belonging to the user.
    #     emails        Unknown       The user's emails.
    #
    # ## Actions
    #
    # **Find**
    #
    # This will return information about an individual user.
    #
    # GET <code>/user/{user.id}</code>
    #
    #     Template Variable  Type     Description
    #     user.id            Integer  Value uniquely identifying the user.
    #     Query Parameter  Type      Description
    #     include          [String]  List of attributes to eager load.
    #
    #     Example: GET /user/119240
    #
    # **Sync**
    #
    # This triggers a sync on a user's account with their GitHub account.
    #
    # POST <code>/user/{user.id}/sync</code>
    #
    #     Template Variable  Type     Description
    #     user.id            Integer  Value uniquely identifying the user.
    #
    #     Example: POST /user/119240/sync
    #
    # **Current**
    #
    # This will return information about the current user.
    #
    # GET <code>/user</code>
    #
    #     Query Parameter  Type      Description
    #     include          [String]  List of attributes to eager load.
    #
    #     Example: GET /user
    #
    # @note sync feature may not be permitted
    # @note POST requests require an authorization token set in the headers. See: {authorization=}
    #
    # @param user_id [String, Integer] optional user id
    # @param sync [Boolean] optional argument for syncing your Travis CI account with GitHub
    # @raise [TypeError] if given user id is not a number
    # @return [Success, RequestError]
    def user(user_id = nil, sync = false)
      return get("#{without_repo}/user") if !user_id && !sync

      validate_number user_id

      if sync
        get("#{without_repo}/user/#{user_id}/sync")
      else
        get("#{without_repo}/user/#{user_id}")
      end
    end

    private # @private

    def create(url, data = {})
      Trav3::REST.create(self, url, data)
    end

    def delete(url)
      Trav3::REST.delete(self, url)
    end

    def env_var_keys(hash)
      inject_property_name('env_var', hash)
    end

    def get(url, raw_reply = false)
      Trav3::REST.get(self, url, raw_reply)
    end

    def get_path(url)
      get("#{without_repo}#{url}")
    end

    def get_path_with_opts(url)
      url, opt = url.match(/(.+)\?(.*)/)&.captures || url
      opts.immutable do |o|
        o.send(:update, opt)
        get_path("#{url}#{opts}")
      end
    end

    def initial_defaults
      defaults(limit: 25)
      h('Content-Type': 'application/json')
      h('Accept': 'application/json')
      h('Travis-API-Version': 3)
    end

    def inject_property_name(name, hash)
      hash.map { |k, v| ["#{name}.#{k}", v] }.to_h unless hash.keys.first.match?(/#{name}\.\w+/)
    end

    def key_pair_keys(hash)
      inject_property_name('key_pair', hash)
    end

    def number?(input)
      /^\d+$/.match? input.to_s
    end

    def opts
      @options
    end

    def patch(url, data)
      Trav3::REST.patch(self, url, data)
    end

    def post(url, body = nil)
      Trav3::REST.post(self, url, body)
    end

    def validate_api_endpoint(input)
      raise InvalidAPIEndpoint unless /^https:\/\/api\.travis-ci\.(?:org|com)$/.match? input
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def validate_env_var(input)
      raise TypeError, "Hash expected, #{input.class} given" unless input.is_a? Hash
      raise EnvVarError unless input.all? do |k, v|
        k.match?(/name|value|public/) &&
        case k.to_s
        when /name/ then v.is_a? String
        when /value/ then v.is_a? String
        when /public/ then [true, false].include? v
        else false
        end
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def validate_number(input)
      raise TypeError, "Integer expected, #{input.class} given" unless number? input
    end

    def validate_repo_format(input)
      raise InvalidRepository unless repo_slug_or_id? input
    end

    def validate_string(input)
      raise TypeError, "String expected, #{input.class} given" unless input.is_a? String
    end

    def repo_slug_or_id?(input)
      Regexp.new(/(^\d+$)|(^[A-Za-z0-9_.-]+(?:\/|%2F){1}[A-Za-z0-9_.-]+$)/i).match? input
    end

    def repository_name
      @repo
    end

    def sanitize_repo_name(repo)
      repo.to_s.gsub(/\//, '%2F')
    end

    def username
      @repo[/.*?(?=(?:\/|%2F)|$)/]
    end

    def with_repo
      "#{api_endpoint}/repo/#{@repo}"
    end

    def without_repo
      api_endpoint
    end

    def without_limit
      limit = opts.remove(:limit)
      result = yield
      opts.build(limit: limit) if limit
      result
    end
  end
end
# rubocop:enable Metrics/ClassLength
