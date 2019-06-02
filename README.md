[![Gem Version](https://badge.fury.io/rb/trav3.svg)](http://badge.fury.io/rb/trav3)
[![Build Status](https://travis-ci.org/danielpclark/trav3.svg?branch=master)](https://travis-ci.org/danielpclark/trav3)
[![Commits Since Release](https://img.shields.io/github/commits-since/danielpclark/trav3/v0.5.1.svg)](https://github.com/danielpclark/trav3/graphs/commit-activity)
[![Maintainability](https://api.codeclimate.com/v1/badges/1ed07a4baea3832b6207/maintainability)](https://codeclimate.com/github/danielpclark/trav3/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/1ed07a4baea3832b6207/test_coverage)](https://codeclimate.com/github/danielpclark/trav3/test_coverage)
[![Red The Docs](https://img.shields.io/badge/Read-the%20docs-blue.svg)](http://danielpclark.github.io/trav3/Trav3/Travis.html)
[![Feature Complete](https://img.shields.io/badge/Feature-Complete-brightgreen.svg)](https://saythanks.io/to/danielpclark)

# Trav3

A simple abstraction layer for Travis CI API v3.

The benefits of this library over the official gem are:

* No gem dependencies
* Designed much like the API documentation
* Handling the returned data is the same for nearly every response
* Little to no learning curve

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'trav3', '~> 1.0.0'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install trav3

## Usage

You can get started with the following.

```ruby
require 'trav3'
project = Trav3::Travis.new("name/example")
```

When you instantiate an instance of [Trav3::Travis](http://danielpclark.github.io/trav3/Trav3/Travis.html)
you get some default headers and default options.

#### Default Options

* `limit: 25` — for limiting data queries to 25 items at most

Options can be changed via the `#options` getter method which will give you a
[Trav3::Options](http://danielpclark.github.io/trav3/Trav3/Options.html) instance.
All changes to it affect the options that the `Trav3::Travis` instance will submit
in url requests.

#### Default Headers

* `'Content-Type': 'application/json'`
* `'Accept': 'application/json'`
* `'Travis-API-Version': 3`

Headers can be changed via the `#headers` getter method which will give you a
[Trav3::Headers](http://danielpclark.github.io/trav3/Trav3/Headers.html) instance.
All changes to it affect the headers that the `Trav3::Travis` instance will submit
in url requests.

## API

The client has the full API implemented.  Here are the methods.

| | | |
|-----|-----|-----|
| [`#active`](http://danielpclark.github.io/trav3/Trav3/Travis.html#active-instance_method) | [`#beta_feature`](http://danielpclark.github.io/trav3/Trav3/Travis.html#beta_feature-instance_method) | [`#beta_features`](http://danielpclark.github.io/trav3/Trav3/Travis.html#beta_features-instance_method) |
| [`#branch`](http://danielpclark.github.io/trav3/Trav3/Travis.html#branch-instance_method) | [`#branches`](http://danielpclark.github.io/trav3/Trav3/Travis.html#branches-instance_method) | [`#broadcasts`](http://danielpclark.github.io/trav3/Trav3/Travis.html#broadcasts-instance_method) |
| [`#build`](http://danielpclark.github.io/trav3/Trav3/Travis.html#build-instance_method) | [`#builds`](http://danielpclark.github.io/trav3/Trav3/Travis.html#builds-instance_method) | [`#build_jobs`](http://danielpclark.github.io/trav3/Trav3/Travis.html#build_jobs-instance_method) |
| [`#caches`](http://danielpclark.github.io/trav3/Trav3/Travis.html#caches-instance_method) | [`#cron`](http://danielpclark.github.io/trav3/Trav3/Travis.html#cron-instance_method) | [`#crons`](http://danielpclark.github.io/trav3/Trav3/Travis.html#crons-instance_method) |
| [`#email_resubscribe`](http://danielpclark.github.io/trav3/Trav3/Travis.html#email_resubscribe-instance_method) | [`#email_unsubscribe`](http://danielpclark.github.io/trav3/Trav3/Travis.html#email_unsubscribe-instance_method) | [`#env_var`](http://danielpclark.github.io/trav3/Trav3/Travis.html#env_var-instance_method) |
| [`#env_vars`](http://danielpclark.github.io/trav3/Trav3/Travis.html#env_vars-instance_method) | [`#installation`](http://danielpclark.github.io/trav3/Trav3/Travis.html#installation-instance_method) | [`#job`](http://danielpclark.github.io/trav3/Trav3/Travis.html#job-instance_method) |
| [`#key_pair`](http://danielpclark.github.io/trav3/Trav3/Travis.html#key_pair-instance_method) | [`#key_pair_generated`](http://danielpclark.github.io/trav3/Trav3/Travis.html#key_pair_generated-instance_method) | [`#lint`](http://danielpclark.github.io/trav3/Trav3/Travis.html#lint-instance_method) |
| [`#log`](http://danielpclark.github.io/trav3/Trav3/Travis.html#log-instance_method) | [`#messages`](http://danielpclark.github.io/trav3/Trav3/Travis.html#messages-instance_method) | [`#organization`](http://danielpclark.github.io/trav3/Trav3/Travis.html#organization-instance_method) |
| [`#organizations`](http://danielpclark.github.io/trav3/Trav3/Travis.html#organizations-instance_method) | [`#owner`](http://danielpclark.github.io/trav3/Trav3/Travis.html#owner-instance_method) | [`#preference`](http://danielpclark.github.io/trav3/Trav3/Travis.html#preference-instance_method) |
| [`#preferences`](http://danielpclark.github.io/trav3/Trav3/Travis.html#preferences-instance_method) | [`#repositories`](http://danielpclark.github.io/trav3/Trav3/Travis.html#repositories-instance_method) | [`#repository`](http://danielpclark.github.io/trav3/Trav3/Travis.html#repository-instance_method) |
| [`#request`](http://danielpclark.github.io/trav3/Trav3/Travis.html#request-instance_method) | [`#requests`](http://danielpclark.github.io/trav3/Trav3/Travis.html#requests-instance_method) | [`#stages`](http://danielpclark.github.io/trav3/Trav3/Travis.html#stages-instance_method) |
| [`#setting`](http://danielpclark.github.io/trav3/Trav3/Travis.html#setting-instance_method) | [`#settings`](http://danielpclark.github.io/trav3/Trav3/Travis.html#settings-instance_method) | [`#user`](http://danielpclark.github.io/trav3/Trav3/Travis.html#user-instance_method) |


**General Usage**

```ruby
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
project.options.build({limit: 25})

# Pagination
builds = project.builds
builds.page.next
builds.page.first
builds.page.last

# Recommended inspection
builds.keys
builds.dig("some_key")

# Follow `@href`
repositories = project.repositories("owner")['repositories']
repositories.first.follow
```

## Response

The results from queries return either `Success` or `RequestError` which both repsond with Hash like query methods for the JSON data or the Net::HTTP resonse object methods.

The `Response` classes `Success` and `RequestError` forward method calls for all of the instance methods of a `ResponseCollection` to the collection.  And for the actual Net::HTTP response the following methods are forwarded from these classes to it:

* `#code`
* `#code_type`
* `#uri`
* `#message`
* `#read_header`
* `#header`
* `#value`
* `#entity`
* `#response`
* `#body`
* `#decode_content`
* `#msg`
* `#reading_body`
* `#read_body`
* `#http_version`
* `#connection_close?`
* `#connection_keep_alive?`
* `#initialize_http_header`
* `#get_fields`
* `#each_header`

The keys for the response are displayed with `#inspect` along with the object.  Opening up any of the items from its key will produce a [`ResponseCollection`](http://danielpclark.github.io/trav3/Trav3/ResponseCollection.html) object that behaves like both an Array or Hash and has a method to [follow](https://github.com/danielpclark/trav3#follow) response links.

`ResponseCollection` uniformly implements:

* `#[]`
* `#dig`
* `#each`
* `#fetch`
* `#first`
* `#follow`
* `#hash?`
* `#last`
* `#warnings`

Which each behave as they would on the collection type per collection type, `Hash` or `Array`, with the exception of `#each`.  `#each` will wrap every item in an `Array` with another `ResponseCollection`, but if it's a `Hash` then `#each` simply works as it normally would on a `Hash`

`ResponseCollection` also forwards:

* `#count`
* `#keys`
* `#values`
* `#has_key?`
* `#key?`
* `empty?`

to the inner collection.

## Follow

Each request returns a `Response` type of either `Success` or `RequestError`.
When you have an instance of `Success` each response collection of either `Hash` or `Array` will
be an instance of `ResponseCollection`.  If the `#hash?` method responds as `true` the `#follow`
method will follow any immediate `@href` link provided in the collection.  If `#hash?` produces `false`
then the collection is an Array of items and you may use the index of the item you want to follow the
`@href` with; like so `#follow(3)`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/danielpclark/trav3.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

