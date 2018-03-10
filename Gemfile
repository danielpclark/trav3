source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in trav3.gemspec
gemspec
group :test do
  gem 'simplecov'
  gem 'codeclimate-test-reporter', '~> 1.0.0'
end

group :test do
  gem 'minitest', '~> 5.10'
  gem 'minitest-reporters', '~> 1.1'
  gem 'color_pound_spec_reporter', '~> 0.0.6'
end

