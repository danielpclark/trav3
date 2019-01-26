[![Gem Version](https://badge.fury.io/rb/trav3.svg)](http://badge.fury.io/rb/trav3)
[![Build Status](https://travis-ci.org/danielpclark/trav3.svg?branch=master)](https://travis-ci.org/danielpclark/trav3)
[![Commits Since Release](https://img.shields.io/github/commits-since/danielpclark/trav3/v0.3.2.svg)](https://github.com/danielpclark/trav3/graphs/commit-activity)
[![Maintainability](https://api.codeclimate.com/v1/badges/1ed07a4baea3832b6207/maintainability)](https://codeclimate.com/github/danielpclark/trav3/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/1ed07a4baea3832b6207/test_coverage)](https://codeclimate.com/github/danielpclark/trav3/test_coverage)
[![Red The Docs](https://img.shields.io/badge/Read-the%20docs-blue.svg)](http://danielpclark.github.io/trav3/Trav3/Travis.html)
[![SayThanks.io](https://img.shields.io/badge/SayThanks.io-%E2%98%BC-1EAEDB.svg)](https://saythanks.io/to/danielpclark)

# Trav3

A simple abstraction layer for Travis CI API v3. The results from queries return either `Success`
or `RequestError` which both repsond with Hash like query methods for the JSON data or the Net::HTTP
resonse object methods.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'trav3'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install trav3

## Usage

    require 'trav3'
    project = Trav3::Travis.new("name/example")
    project.owner
    project.owner("owner")
    project.repositories
    project.repositories("owner")
    project.repository
    project.repository("owner/repo")
    project.builds
    project.build(12345)
    project.build_jobs(12345)
    project.job(1234)
    project.log(1234)
    
    # API Request Options
    project.defaults(limit: 25)
    
    # Pagination
    builds = project.builds
    builds.page.next
    builds.page.first
    builds.page.last
    
    # Recommended inspection
    builds.keys
    builds.dig("some_key")

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/danielpclark/trav3.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

