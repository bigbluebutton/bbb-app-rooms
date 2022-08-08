# frozen_string_literal: true

# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/.
# Copyright (c) 2018 BigBlueButton Inc. and by respective authors (see below).
# This program is free software; you can redistribute it and/or modify it under the
# terms of the GNU Lesser General Public License as published by the Free Software
# Foundation; either version 3.0 of the License, or (at your option) any later
# version.
#
# BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
# You should have received a copy of the GNU Lesser General Public License along
# with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  config.public_file_server.enabled = true
  config.action_controller.perform_caching = true if Rails.root.join('tmp/caching-dev.txt').exist?
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{2.days.to_i}",
  }
  config.cache_store = if ENV['REDIS_URL'].present?
                         # Set up Redis cache store
                         [:redis_cache_store, { url: ENV['REDIS_URL'],

                                                connect_timeout: 30, # Defaults to 20 seconds
                                                read_timeout: 0.2, # Defaults to 1 second
                                                write_timeout: 0.2, # Defaults to 1 second
                                                reconnect_attempts: 1, },] # Defaults to 0,]
                       else
                         :memory_store
                       end

  config.action_controller.perform_caching = true

  # Store uploaded files on the local file system (see config/storage.yml for options)
  config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  config.hosts = nil

  config.relative_url_root = "#{ENV['RELATIVE_URL_ROOT'] ? '/' + ENV['RELATIVE_URL_ROOT'] : 'apps'}/rooms"
  config.assets.prefix = "#{ENV['RELATIVE_URL_ROOT'] ? '/' + ENV['RELATIVE_URL_ROOT'] : 'apps'}/rooms/assets"

  config.web_console.whiny_requests = false
end
