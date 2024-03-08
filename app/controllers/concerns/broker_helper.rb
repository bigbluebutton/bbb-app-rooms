# frozen_string_literal: true

# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/.
# Copyright (c) 2018 BigBlueButton Inc. and by respective authors (see below).
# This program is free software; you can redistribute it and/or modify it under the
# terms of the GNU Lesser General Public License as published by the Free Software
# Foundation; either version 3.0 of the License, or (at your option) any later
# version.
# BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

# You should have received a copy of the GNU Lesser General Public License along
# with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.

module BrokerHelper
  extend ActiveSupport::Concern

  include OmniauthHelper

  # Fetch tenant settings from the broker
  def tenant_settings(options = {})
    tenant = options[:tenant] || @room&.tenant || ''
    bbbltibroker_url = omniauth_bbbltibroker_url("/api/v1/tenants/#{tenant}")
    get_response = RestClient.get(bbbltibroker_url, 'Authorization' => "Bearer #{omniauth_client_token(omniauth_bbbltibroker_url)}")

    JSON.parse(get_response)
  rescue StandardError => e
    Rails.logger.error("Could not fetch tenant credentials from broker. Error message: #{e}")
    nil
  end

  # Fetch the params to use when creating the room handler
  def handler_params(tenant)
    tenant_settings(tenant: tenant)&.[]('settings')&.[]('handler_params')&.split(',')
  end

  # See whether shared rooms have been enabled in tenant settings. They are disabled by default.
  def shared_rooms_enabled(tenant)
    Rails.cache.fetch("rooms/tenant_settings/shared_rooms_enabled/#{tenant}", expires_in: 1.hour) do
      tenant_settings(tenant: tenant)&.[]('settings')&.[]('enable_shared_rooms') == 'true' || false
    end
  end

  def hide_build_tag(tenant)
    tenant_settings(tenant: tenant)&.[]('settings')&.[]('hide_build_tag') == 'true' || false
  end

  def bbb_moderator_roles_params(tenant)
    tenant_settings(tenant: tenant)&.[]('settings')&.[]('bigbluebutton_moderator_roles')&.split(',')
  end
end
