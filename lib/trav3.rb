# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
require 'trav3/version'
require 'trav3/pagination'
require 'trav3/options'
require 'trav3/headers'
require 'trav3/result'
require 'trav3/delete'
require 'trav3/post'
require 'trav3/get'

# Trav3 project namespace
module Trav3
  API_ROOT = 'https://api.travis-ci.org'

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
    API_ENDPOINT = API_ROOT
    attr_reader :api_endpoint
    attr_reader :options
    attr_reader :headers

    # @param repo [String] github_username/repository_name
    # @raise [InvalidRepository] if given input does not
    #   conform to valid repository identifier format
    # @return [Travis]
    def initialize(repo)
      validate_repo_format repo

      @api_endpoint = API_ENDPOINT
      @repo = sanitize_repo_name repo

      initial_defaults
    end

    # @overload api_endpoint=(endpoint)
    #   Set as the API endpoint
    #   @param endpoint [String] name for value to set
    # @return [self]
    # rubocop:disable Lint/Void
    def api_endpoint=(endpoint)
      validate_api_endpoint endpoint

      @api_endpoint = endpoint

      self
    end
    # rubocop:enable Lint/Void

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
    #     Example:GET /repo/891/branch/master
    #
    # GET <code>/repo/{repository.slug}/branch/{branch.name}</code>
    #
    #     Template Variable  Type    Description
    #     repository.slug    String  Same as {repository.owner.name}/{repository.name}.
    #     branch.name        String  Name of the git branch.
    #     Query Parameter  Type      Description
    #     include          [String]  List of attributes to eager load.
    #
    #     Example:GET /repo/rails%2Frails/branch/master
    #
    # @param name [String] the branch name for the current repository
    # @return [Success, RequestError]
    def branch(name)
      get("#{with_repo}/branch/#{name}#{opts}")
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
    #     Example:GET /repo/891/branches?limit=5&exists_on_github=true
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
    #     Example:GET /repo/rails%2Frails/branches?limit=5&exists_on_github=true
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
    # @note POST requests require an authorization token set in the headers. See: {h}
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
    # @note DELETE requests require an authorization token set in the headers. See: {h}
    #
    # @param delete [Boolean] option for deleting cache(s)
    # @return [Success, RequestError]
    def caches(delete = false)
      if delete
        limit = opts.remove(:limit)
        response = delete("#{with_repo}/caches#{opts}")
        opts.build(limit: limit) if limit
        response
      else
        get("#{with_repo}/caches")
      end
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
    # @note POST requests require an authorization token set in the headers. See: {h}
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
    #     Example:POST /lint
    #
    # @param yaml_content [String] the contents for the file `.travis.yml`
    # @return [Success, RequestError]
    def lint(yaml_content)
      validate_string yaml_content

      ct = headers.remove(:'Content-Type')
      result = post("#{without_repo}/lint", body: yaml_content)
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
    #     Example:GET /job/86601347/log.txt
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
    #     Example:GET /org/87
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
    #     Example:GET /orgs?limit=5
    #
    # **Sortable by:** <code>id</code>, <code>login</code>, <code>name</code>, <code>github_id</code>, append <code>:desc</code> to any attribute to reverse order.
    #
    # @return [Success, RequestError]
    def organizations
      get("#{without_repo}/orgs")
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
      if number? owner
        get("#{without_repo}/owner/github_id/#{owner}")
      else
        get("#{without_repo}/owner/#{owner}")
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
    # **Sortable by:** <code>id</code>, <code>github_id</code>, <code>owner_name</code>, <code>name</code>, <code>active</code>, <code>default_branch.last_build</code>, append <code>:desc</code> to any attribute to reverse order.
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
    # **Sortable by:** <code>id</code>, <code>github_id</code>, <code>owner_name</code>, <code>name</code>, <code>active</code>, <code>default_branch.last_build</code>, append <code>:desc</code> to any attribute to reverse order.
    #
    # @param owner [String] username or github ID
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
    # @note POST requests require an authorization token set in the headers. See: {h}
    #
    # @param repo [String] github_username/repository_name
    # @param action [String, Symbol] Optional argument for star/unstar/activate/deactivate
    # @raise [InvalidRepository] if given input does not
    #   conform to valid repository identifier format
    # @return [Success, RequestError]
    def repository(repo = repository_name, action = nil)
      validate_repo_format repo

      repo = sanitize_repo_name repo
      action = '' unless %w[star unstar activate deavtivate].include? action.to_s

      if action.empty?
        get("#{without_repo}/repo/#{repo}")
      else
        post("#{without_repo}/repo/#{repo}/#{action}")
      end
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
    #     Example:GET /build/86601346/stages
    #
    # @param build_id [String, Integer] build id
    # @raise [TypeError] if given build id is not a number
    # @return [Success, RequestError]
    def stages(build_id)
      validate_number build_id

      get("#{without_repo}/build/#{build_id}/stages")
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
    #     login String   Login set on Github.
    #
    # **Standard Representation**
    #
    # Included when the resource is the main response of a request, or is {https://developer.travis-ci.com/eager-loading eager loaded}.
    #
    #     Name              Type     Description
    #     id                Integer  Value uniquely identifying the user.
    #     login             String   Login set on Github.
    #     name              String   Name set on GitHub.
    #     github_id         Integer  Id set on GitHub.
    #     avatar_url        String   Avatar URL set on GitHub.
    #     education         Boolean  Whether or not the user has an education account.
    #     allow_migration   Unknown  The user's allow_migration.
    #     is_syncing        Boolean  Whether or not the user is currently being synced with Github.
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
    #     Example:GET /user/119240
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
    #     Example:POST /user/119240/sync
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
    #     Example:GET /user
    #
    # @note sync feature may not be permitted
    # @note POST requests require an authorization token set in the headers. See: {h}
    #
    # @param user_id [String, Integer] optional user id
    # @param sync [Boolean] optional argument for syncing your Travis CI account with Github
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

    def delete(url)
      Trav3::DELETE.call(self, url)
    end

    def get(url, raw_reply = false)
      Trav3::GET.call(self, url, raw_reply)
    end

    def initial_defaults
      defaults(limit: 25)
      h('Content-Type': 'application/json')
      h('Accept': 'application/json')
      h('Travis-API-Version': 3)
    end

    def number?(input)
      /^\d+$/.match? input.to_s
    end

    def opts
      @options
    end

    def post(url, fields = {})
      Trav3::POST.call(self, url, fields)
    end

    def validate_api_endpoint(input)
      raise InvalidAPIEndpoint unless /^https:\/\/api\.travis-ci\.(?:org|com)$/.match? input
    end

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
      Regexp.new(/(^\d+$)|(^\w+(?:\/|%2F){1}\w+$)/).match? input
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
  end
end
# rubocop:enable Metrics/ClassLength
