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

# Pre-set omniauth variables based on ENV
Rails.configuration.omniauth_site = ENV['OMNIAUTH_BBBLTIBROKER_SITE'] || ''
Rails.configuration.omniauth_root = "/#{ENV['OMNIAUTH_BBBLTIBROKER_ROOT'] || 'lti'}"
Rails.configuration.omniauth_key = ENV['OMNIAUTH_BBBLTIBROKER_KEY'] || ''
Rails.configuration.omniauth_secret = ENV['OMNIAUTH_BBBLTIBROKER_SECRET'] || ''

OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use(OmniAuth::Builder) do
  # Initialize the provider
  unless Rails.configuration.omniauth_site.empty? || Rails.configuration.omniauth_key.empty? || Rails.configuration.omniauth_secret.empty?
    provider(
      :bbbltibroker,
      Rails.configuration.omniauth_key,
      Rails.configuration.omniauth_secret,
      provider_ignores_state: true,
      path_prefix: "#{Rails.configuration.relative_url_root}/auth",
      omniauth_root: Rails.configuration.omniauth_root.to_s,
      raw_info_url: "#{Rails.configuration.omniauth_root}/api/v1/user.json",
      scope: 'api',
      info_params: %w[
        full_name
        first_name
        last_name
        email
      ],
      client_options: {
        site: Rails.configuration.omniauth_site.to_s,
        code: 'rooms',
        authorize_url: "#{Rails.configuration.omniauth_root}/oauth/authorize",
        token_url: "#{Rails.configuration.omniauth_root}/oauth/token",
        revoke_url: "#{Rails.configuration.omniauth_root}/oauth/revoke",
      }
    )
  end
end
