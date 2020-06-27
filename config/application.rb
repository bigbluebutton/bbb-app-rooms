# frozen_string_literal: true

require_relative 'boot'
require 'rails/all'

# Load the app's custom environment variables here, so that they are loaded before environments/*.rb

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module BbbAppRooms
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.url_host = ENV['URL_HOST']

    config.build_number = ENV['BUILD_NUMBER'] || 'v1'

    config.bigbluebutton_endpoint = ENV['BIGBLUEBUTTON_ENDPOINT'] || 'http://test-install.blindsidenetworks.com/bigbluebutton/api'
    config.bigbluebutton_secret = ENV['BIGBLUEBUTTON_SECRET'] || '8cd8ef52e8e101574e400365b55e11a6'
    config.bigbluebutton_moderator_roles = ENV['BIGBLUEBUTTON_MODERATOR_ROLES'] || 'Instructor,Faculty,Teacher,Mentor,Administrator,Admin'

    config.omniauth_path_prefix = "#{ENV['RELATIVE_URL_ROOT'] ? '/' + ENV['RELATIVE_URL_ROOT'] : ''}/rooms/auth"
    config.omniauth_site = ENV['OMNIAUTH_BBBLTIBROKER_SITE'] || 'http://localhost:3000'
    config.omniauth_root = (ENV['OMNIAUTH_BBBLTIBROKER_ROOT'] ? '/' + ENV['OMNIAUTH_BBBLTIBROKER_ROOT'] : '').to_s
    config.omniauth_key = ENV['OMNIAUTH_BBBLTIBROKER_KEY'] || ''
    config.omniauth_secret = ENV['OMNIAUTH_BBBLTIBROKER_SECRET'] || ''

    config.default_timezone = ENV["DEFAULT_TIMEZONE"] || 'UTC'
    config.app_name = ENV["APP_NAME"] || 'BbbAppRooms'

    config.session_duration_mins =
      ENV["APP_SESSION_DURATION_MINS"].try(:to_i).try(:minutes) || 30.minutes

    config.theme = ENV['APP_THEME']
    unless config.theme.blank?
      config.paths['app/helpers']
        .unshift(Rails.root.join('themes', config.theme, 'helpers'))
      config.paths['app/views']
        .unshift(Rails.root.join('themes', config.theme, 'mailers', 'views'))
        .unshift(Rails.root.join('themes', config.theme, 'views'))
      I18n.load_path +=
        Dir[Rails.root.join('themes', config.theme, 'config', 'locales', '*.{rb,yml}')]
      # see config/initializers/assets for more theme configs
    end
  end
end
