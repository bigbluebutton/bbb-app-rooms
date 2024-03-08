# frozen_string_literal: true

source 'http://rubygems.org'
git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.1'
# Use sqlite3 as the database for Active Record
# gem 'sqlite3', '~> 1.3'
# Use postgres as the database for Active Record
gem 'pg', '~> 1.0'
# Use Puma as the app server
gem 'puma', '~> 5.6', '>= 5.6.8'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 6.0', '>= 6.0.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'mini_racer', platforms: :ruby

# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.11', '>= 2.11.5'
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 4.2'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Reduces boot times through caching; required in config/boot.rb
# gem 'bootsnap', '>= 1.1.0', require: false

# Front-end.
gem 'pagy'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'action-cable-testing'
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'dotenv-rails', '>= 3.0.0'
  gem 'rspec'
  gem 'rspec_junit_formatter'
  gem 'rspec-rails', '~> 5.1.0'
  gem 'rubocop', '~> 1.54', require: false
  gem 'rubocop-rails', '~> 2.24', '>= 2.24.0', require: false
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'web-console', '>= 4.2.1'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 3.40.0' # , '>= 2.15', '< 4.0'
  gem 'selenium-webdriver'
  # Easy installation and use of chromedriver to run system tests with Chrome
  # gem 'chromedriver-helper'
  gem 'database_cleaner-active_record'
  gem 'factory_bot_rails', '>= 6.4.3'
  gem 'faker'
  gem 'rails-controller-testing'
  gem 'webdrivers'
  gem 'webmock'
end

group :production do
  gem 'lograge', '~> 0.14.0'
  gem 'remote_syslog_logger'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data'

gem 'json'

gem 'bigbluebutton-api-ruby', '~> 1.9.1'

gem 'rest-client'

gem 'omniauth', '>= 2.1.2'
gem 'omniauth-oauth2', '>= 1.8.0'
gem 'omniauth-rails_csrf_protection', '~> 1.0.1'
gem 'repost', '~> 0.4.1'

gem 'minitest'
gem 'omniauth-bbbltibroker', git: 'https://github.com/bigbluebutton/omniauth-bbbltibroker.git', tag: '0.1.4'

gem 'activerecord-session_store', '>= 2.1.0'

gem 'coveralls_reborn', require: false
gem 'net-smtp'
gem 'webpacker', '~> 6.0.0.rc.5'

gem 'rdoc', require: false
