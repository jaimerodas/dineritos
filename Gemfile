source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby File.read(".ruby-version").strip

gem "bcrypt"
gem "lockbox"
gem "money-rails"
gem "httparty"
gem "rails", "~> 6.1"
gem "pg", ">= 0.18", "< 2.0"
gem "postmark-rails"
gem "puma", "~> 4.3"
gem "sass-rails", "~> 6"
gem "turbolinks", "~> 5"
gem "watir"
gem "webpacker", "~> 5.2"
gem "will_paginate", "~> 3.3"
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
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
  gem "listen", ">= 3.0.5", "< 3.2"
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"
  # gem "i18n-debug"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]
