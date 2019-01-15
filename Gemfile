source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in trav3.gemspec
gemspec

group :test do
  gem 'byebug'
  gem 'codeclimate-test-reporter', '~> 1.0.0'
  gem 'rubocop', require: false
  gem 'simplecov', require: false
  gem 'vcr', '~> 4.0'
  gem 'webmock', '~> 3.5'
  gem 'yard', require: false
end
