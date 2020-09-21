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

  # Generates URL for joining the current @room meeting.
  def join_meeting_url
    return unless @room && @user

    unless bbb
      @error = {
        key: t('error.bigbluebutton.invalidrequest.code'),
        message: t('error.bigbluebutton.invalidrequest.message'),
        suggestion: t('error.bigbluebutton.invalidrequest.suggestion'),
        status: :internal_server_error,
      }
      return
    end

    create_meeting
    role = @user.moderator?(bigbluebutton_moderator_roles) || @room.all_moderators ? 'moderator' : 'viewer'
    bbb.join_meeting_url(@room.handler, @user.username(t("default.bigbluebutton.#{role}")), @room.attributes[role])
  end

  # Create meeting for the current @room.
  def create_meeting
    create_options = {
      moderatorPW: @room.moderator,
      attendeePW: @room.viewer,
      welcome: @room.welcome,
      record: @room.recording,
      logoutURL: autoclose_url,
      "meta_description": @room.description
    }

    # Send the create request.
    begin
      meeting = bbb.create_meeting(@room.name, @room.handler, create_options)
    rescue BigBlueButton::BigBlueButtonException => e
      logger.info "BigBlueButton failed on create: #{e.key}: #{e.message}"
      raise e
    end

  end

  # Perform ends meeting for the current @room.
  def end_meeting
    bbb.end_meeting(@room.handler, @room.moderator)
  end

  # Retrieves meeting info for the current Room.
  def meeting_info
    info = {returncode: 'FAILED'}
    begin
      info = bbb.get_meeting_info(@room.handler, @user)
    rescue BigBlueButton::BigBlueButtonException => e
    end
    info
  end

  # Checks if the meeting for current @room is running.
  def meeting_running?
      bbb.is_meeting_running?(@room.handler)
  end

  # Deletes a recording.
  def delete_recording(record_id)
    bbb.delete_recordings(record_id)
  end

  # Publishes a recording.
  def publish_recording(record_id)
    bbb.publish_recordings(record_id, true)
  end

  # Unpublishes a recording.
  def unpublish_recording(record_id)
    bbb.publish_recordings(record_id, false)
  end

  # Updates a recording.
  def update_recording(record_id, meta)
    meta[:recordID] = record_id
    bbb.send_api_request('updateRecordings', meta)
  end

  # Check if the current @user must wait_for_moderator to join the current @room.
  def wait_for_mod?
    return unless @room && @user

    @room.wait_moderator && !@user.moderator?(bigbluebutton_moderator_roles)
  end

  # Return the number of participants in a meeting for the current room.
  def participant_count
    info = meeting_info
    return info[:participantCount] if info[:returncode] == 'SUCCESS'
  end

  # Return the meeting start time for the current room.
  def meeting_start_time
    info = meeting_info
    return info[:startTime] if info[:returncode] == 'SUCCESS'
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
