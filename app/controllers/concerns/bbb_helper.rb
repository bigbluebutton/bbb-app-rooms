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

module BbbHelper
  extend ActiveSupport::Concern

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
      'meta_description': @room.description,
    }
    # Send the create request.
    bbb.create_meeting(@room.name, @room.handler, create_options)
  end

  # Perform ends meeting for the current @room.
  def end_meeting
    bbb.end_meeting(@room.handler, @room.moderator)
  end

  # Retrieves meeting info for the current Room.
  def meeting_info
    info = { returncode: 'FAILED' }
    begin
      info = bbb.get_meeting_info(@room.handler, @user)
    rescue BigBlueButton::BigBlueButtonException
      logger.info('We could not find a meeting with that meeting ID')
    end
    info
  end

  # Checks if the meeting for current @room is running.
  def meeting_running?
    bbb.is_meeting_running?(@room.handler)
  end

  # Fetches all recordings for a room.
  def recordings
    res = bbb.get_recordings(meetingID: @room.handler)

    # Format playbacks in a more pleasant way.
    res[:recordings].each do |r|
      next if r.key?(:error)

      r[:playbacks] = if !r[:playback] || !r[:playback][:format]
                        []
                      elsif r[:playback][:format].is_a?(Array)
                        r[:playback][:format]
                      else
                        [r[:playback][:format]]
                      end

      r.delete(:playback)
    end

    res[:recordings].sort_by { |rec| rec[:endTime] }.reverse
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

  def bigbluebutton_moderator_roles
    Rails.configuration.bigbluebutton_moderator_roles.split(',')
  end

  def bigbluebutton_recording_public_formats
    Rails.configuration.bigbluebutton_recording_public_formats.split(',')
  end

  # Helper for converting BigBlueButton dates into the desired format.
  def recording_date(date)
    # note: if we really wanted ordinalization, then we can add an if statement to ordinalize if locale is en.
    # .ordinalize does not work with other locales
    return date.strftime("%B #{date.day}, %Y.") unless I18n.locale.eql?(:en)

    date.strftime("%B #{date.day.ordinalize}, %Y.")
  end

  # Helper for converting BigBlueButton dates into a nice length string.
  def recording_length(playbacks)
    # Stats format currently doesn't support length.
    valid_playbacks = playbacks.reject { |p| p[:type] == 'statistics' }
    return '0 min' if valid_playbacks.empty?

    len = valid_playbacks.first[:length]
    if len > 60
      "#{(len / 60).round} hrs"
    elsif len.zero?
      '< 1 min'
    else
      "#{len} min"
    end
  end

  private

  # Emulates a builder for initializing the a newly created Bbb::Credentials object.
  def initialize_bbb_credentials
    bbb_credentials = Bbb::Credentials.new(Rails.configuration.bigbluebutton_endpoint, Rails.configuration.bigbluebutton_secret)
    bbb_credentials.multitenant_api_endpoint = Rails.configuration.external_multitenant_endpoint
    bbb_credentials.multitenant_api_secret = Rails.configuration.external_multitenant_secret
    bbb_credentials.cache = Rails.cache
    bbb_credentials.cache_enabled = Rails.configuration.cache_enabled
    bbb_credentials
  end

  # Removes trailing forward slash from a URL.
  def remove_slash(str)
    str.nil? ? nil : str.chomp('/')
  end
end
