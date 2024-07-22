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

# Be sure to restart your server when you modify this file.

# Define allowed values for SameSite attribute
same_site_allowed_values = %w[Strict Lax None]

same_site = if ENV['COOKIES_SAME_SITE'].present?
              value = ENV['COOKIES_SAME_SITE'].capitalize
              same_site_allowed_values.include?(value) ? value : 'None'
            else
              'None' # Default value if not present or invalid
            end

attrs = {
  key: '_bbb_app_rooms_session',
  secure: ENV['COOKIES_SECURE'].blank? || ENV['COOKIES_SECURE'].downcase == 'true',
  same_site: same_site,
}

Rails.application.config.session_store(:active_record_store, **attrs)

Rails.logger.class.include ActiveSupport::LoggerSilence
