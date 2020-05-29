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

    config.bigbluebutton_endpoint = ENV['BIGBLUEBUTTON_ENDPOINT'] || "http://test-install.blindsidenetworks.com/bigbluebutton/api"
    config.bigbluebutton_secret = ENV['BIGBLUEBUTTON_SECRET'] || "8cd8ef52e8e101574e400365b55e11a6"
    config.bigbluebutton_moderator_roles = ENV['BIGBLUEBUTTON_MODERATOR_ROLES'] || "Instructor,Faculty,Teacher,Mentor,Administrator,Admin"

    config.omniauth_path_prefix = "#{ENV['RELATIVE_URL_ROOT'] ? '/' + ENV['RELATIVE_URL_ROOT'] : ''}/rooms/auth"
    config.omniauth_site = ENV['OMNIAUTH_BBBLTIBROKER_SITE'] || "http://localhost:3000"
    config.omniauth_root = "#{ENV['OMNIAUTH_BBBLTIBROKER_ROOT'] ? '/' + ENV['OMNIAUTH_BBBLTIBROKER_ROOT'] : ''}"
    config.omniauth_key = ENV["OMNIAUTH_BBBLTIBROKER_KEY"] || ''
    config.omniauth_secret = ENV["OMNIAUTH_BBBLTIBROKER_SECRET"] || ''
  end
end
