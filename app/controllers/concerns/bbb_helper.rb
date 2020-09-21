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

require 'bbb/credentials'
require 'bbb/helper'

module BbbHelper
  extend ActiveSupport::Concern
  include Bbb::Helper

  # Sets a BigBlueButtonApi object for interacting with the API.
  def bbb
    @bbb_credentials ||= initialize_bbb_credentials
    BigBlueButton::BigBlueButtonApi.new(remove_slash(@bbb_credentials.endpoint(@room.tenant)), @bbb_credentials.secret(@room.tenant), '0.9', 'true')
  end

  # Ends a meeting.
  def end_meeting
    bbb.end_meeting(@room.handler, @room.moderator)
  end

  # Deletes a recording from a room.
  def delete_recording(record_id)
    bbb.delete_recordings(record_id)
  end

  # Publishes a recording for a room.
  def publish_recording(record_id)
    bbb.publish_recordings(record_id, true)
  end

  # Unpublishes a recording for a room.
  def unpublish_recording(record_id)
    bbb.publish_recordings(record_id, false)
  end

  # Update recording for a room.
  def update_recording(record_id, meta)
    meta[:recordID] = record_id
    bbb.send_api_request('updateRecordings', meta)
  end

  private

  def initialize_bbb_credentials
    bbb_credentials = Bbb::Credentials.new(Rails.configuration.bigbluebutton_endpoint, Rails.configuration.bigbluebutton_secret)
    bbb_credentials.multitenant_api_endpoint = Rails.configuration.external_multitenant_endpoint
    bbb_credentials.multitenant_api_secret = Rails.configuration.external_multitenant_secret
    bbb_credentials.cache = Rails.cache
    bbb_credentials.cache_enabled = Rails.configuration.cache_enabled
    bbb_credentials
  end
end
