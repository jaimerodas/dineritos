source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby File.read(".ruby-version").strip

gem "bcrypt"
gem "lockbox"
gem "money-rails"
gem "httparty"
gem "rails", "~> 7"
gem "pg", ">= 0.18", "< 2.0"
gem "postmark-rails"
gem "puma", "~> 5.6"
gem "sass-rails", "~> 6"
gem "stimulus-rails"
gem "turbolinks", "~> 5"
gem "watir"
gem "will_paginate", "~> 3.3"
gem "webauthn"
gem "jbuilder", "~> 2"
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", ">= 1.4.2", require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
  gem "rspec-rails"
end

group :development do
  gem "standardrb"
  gem "letter_opener"
  gem "pry"
  gem "web-console", ">= 3.3.0"
  gem "listen"
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"
  # gem "i18n-debug"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem "importmap-rails", "~> 1.1"
