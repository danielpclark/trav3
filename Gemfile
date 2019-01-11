source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in trav3.gemspec
gemspec
group :test do
  gem 'simplecov', require: false, group: :test
  gem 'codeclimate-test-reporter', '~> 1.0.0'
end
