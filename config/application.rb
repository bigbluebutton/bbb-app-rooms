# frozen_string_literal: true

require_relative 'boot'
require 'rails/all'
require_relative '../lib/simple_json_formatter'

# Load the app's custom environment variables here, so that they are loaded before environments/*.rb

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module BbbAppRooms
  class Application < Rails::Application
    VERSION = "0.4.3-elos"

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.url_host = ENV['URL_HOST']
    config.relative_url_root = if ENV['RELATIVE_URL_ROOT'].blank?
                                 '/rooms'
                               else
                                 "/#{ENV['RELATIVE_URL_ROOT']}/rooms"
                               end

    config.build_number = ENV['BUILD_NUMBER'] || VERSION

    config.bigbluebutton_endpoint = ENV['BIGBLUEBUTTON_ENDPOINT'] || 'http://test-install.blindsidenetworks.com/bigbluebutton/api'
    config.bigbluebutton_endpoint_internal = ENV['BIGBLUEBUTTON_ENDPOINT_INTERNAL']
    config.bigbluebutton_secret = ENV['BIGBLUEBUTTON_SECRET'] || '8cd8ef52e8e101574e400365b55e11a6'
    config.bigbluebutton_moderator_roles =
      ENV['BIGBLUEBUTTON_MODERATOR_ROLES'] ||
      'Instructor,Faculty,Teacher,Mentor,Administrator,Admin'

    config.omniauth_path_prefix = if ENV['RELATIVE_URL_ROOT'].blank?
                                    '/rooms/auth'
                                  else
                                    "/#{ENV['RELATIVE_URL_ROOT']}/rooms/auth"
                                  end
    config.omniauth_site = {}
    config.omniauth_site[:bbbltibroker] = ENV['OMNIAUTH_BBBLTIBROKER_SITE'] || 'http://localhost:3000'
    config.omniauth_root = {}
    config.omniauth_root[:bbbltibroker] = (
      ENV['OMNIAUTH_BBBLTIBROKER_ROOT'] ? '/' + ENV['OMNIAUTH_BBBLTIBROKER_ROOT'] : ''
    ).to_s
    config.omniauth_key = {}
    config.omniauth_key[:bbbltibroker] = ENV['OMNIAUTH_BBBLTIBROKER_KEY'] || ''
    config.omniauth_secret = {}
    config.omniauth_secret[:bbbltibroker] = ENV['OMNIAUTH_BBBLTIBROKER_SECRET'] || ''

    # Spaces API config
    config.spaces_key = ENV['SPACES_KEY'] || ''
    config.spaces_secret = ENV['SPACES_SECRET'] || ''
    config.spaces_bucket = ENV['SPACES_BUCKET'] || ''
    config.spaces_endpoint = ENV['SPACES_ENDPOINT'] || 'https://nyc3.digitaloceanspaces.com'
    config.spaces_common_prefix = ENV['SPACES_COMMON_PREFIX'] || 'lti/'

    config.assets.prefix = if ENV['RELATIVE_URL_ROOT'].blank?
                             '/rooms/assets'
                           else
                             "/#{ENV['RELATIVE_URL_ROOT']}/rooms/assets"
                           end

    config.default_timezone = ENV["DEFAULT_TIMEZONE"] || 'UTC'
    config.force_default_timezone = ENV['FORCE_DEFAULT_TIMEZONE'] == 'true'

    config.app_name = ENV["APP_NAME"] || 'BbbAppRooms'

    config.launch_duration_mins =
      ENV["APP_LAUNCH_DURATION_MINS"].try(:to_i).try(:minutes) || 30.minutes

    config.log_level = ENV['LOG_LEVEL'] || :debug

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

    config.cable_enabled = ENV['CABLE_ENABLED'] == '1' || ENV['CABLE_ENABLED'] == 'true'
    config.cable_btn_timeout = ENV['CABLE_BTN_TIMEOUT'] || 60000

    # use a json formatter to match lograge's logs
    if ENV['LOGRAGE_ENABLED'] == '1'
      config.log_formatter = SimpleJsonFormatter.new
    end

    config.browser_time_zone_secure_cookie = ENV['COOKIES_SECURE_OFF'].blank?
    config.browser_time_zone_same_site_cookie =
      ENV['COOKIES_SAME_SITE'].blank? ? 'None' : "#{ENV['COOKIES_SAME_SITE']}"
    config.browser_time_zone_default_tz = config.default_timezone
  end
end
