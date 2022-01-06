source "https://rubygems.org"

gemspec

gem 'listen', '< 3.1'
active_model_version = ENV['ACTIVE_MODEL_VERSION']
gem 'activemodel', "~> #{active_model_version}" if active_model_version&.length&.positive?

#gem 'zeitwerk'

group :test do
  gem 'coveralls', require: false
  gem 'overcommit'
  gem 'codecov', require: false
  gem 'simplecov', require: false
  gem 'simplecov-html', require: false
  gem 'its'
  gem 'test-unit'
  gem 'colored'
  gem 'dotenv'
  gem 'timecop'
  gem 'pry'
  gem 'activegraph'
end