source "https://rubygems.org"

ruby "3.4.7"

# Core Rails framework
gem "rails", "~> 8.1"

# Database & Models
gem "pg", ">= 0.18", "< 2.0"
gem "money-rails"

# Authentication & Security
gem "bcrypt"
gem "lockbox"
gem "webauthn"

# Web Server & Assets
gem "puma"
gem "propshaft"
gem "stimulus-rails"
gem "importmap-rails", "~> 1.1"

# API & HTTP
gem "httparty"
gem "postmark-rails"

# UI & Pagination
gem "jbuilder", "~> 2"
gem "will_paginate", "~> 3.3"

# Scheduling
gem "whenever", require: false

# System Dependencies
gem "ostruct"

# Performance
gem "bootsnap", ">= 1.4.2", require: false

group :development, :test do
  gem "byebug", platforms: [:mri, :windows]
  gem "rspec-rails"
end

group :development do
  gem "standardrb"
  gem "letter_opener"
  gem "pry"
  gem "web-console", ">= 3.3.0"
  gem "listen"
  gem "mutex_m"
end

group :test do
  gem "simplecov"
  gem "simplecov-cobertura"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [:windows, :jruby]
