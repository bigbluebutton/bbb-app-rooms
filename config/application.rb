# frozen_string_literal: true

#  BigBlueButton open source conferencing system - http://www.bigbluebutton.org/.
#
#  Copyright (c) 2018 BigBlueButton Inc. and by respective authors (see below).
#
#  This program is free software; you can redistribute it and/or modify it under the
#  terms of the GNU Lesser General Public License as published by the Free Software
#  Foundation; either version 3.0 of the License, or (at your option) any later
#  version.
#
#  BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
#  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
#  PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public License along
#  with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.

require_relative 'boot'
require 'rails/all'

# Load the app's custom environment variables here, so that they are loaded before environments/*.rb

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module BbbAppRooms
  class Application < Rails::Application
    # Configure I18n localization.
    config.i18n.available_locales = [:en, :pt]
    config.i18n.default_locale = :en

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

    # Mount Action Cable outside main process or domain
    config.action_cable.url = "wss://#{ENV['URL_HOST']}#{ENV['RELATIVE_URL_ROOT'] ? '/' + ENV['RELATIVE_URL_ROOT'] : ''}/rooms/cable"
  end
end
