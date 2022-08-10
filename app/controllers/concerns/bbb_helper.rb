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
  attr_writer :cache, :cache_enabled # Rails.cache store is assumed.  # Enabled by default.

  # Sets a BigBlueButtonApi object for interacting with the API.
  def bbb
    @bbb_credentials ||= initialize_bbb_credentials
    bbb_url = remove_slash(@bbb_credentials.endpoint(@room.tenant))
    bbb_secret = @bbb_credentials.secret(@room.tenant)
    BigBlueButton::BigBlueButtonApi.new(bbb_url, bbb_secret, '1.0', Rails.logger)
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
    join_options = {}
    join_options[:createTime] = meeting_info[:createTime]
    bbb.join_meeting_url(@room.handler, @user.username(t("default.bigbluebutton.#{role}")), @room.attributes[role], join_options)
  end

  # Create meeting for the current @room.
  def create_meeting
    record = bigbluebutton_recording_enabled ? @room.recording : false
    create_options = {
      moderatorPW: @room.moderator,
      attendeePW: @room.viewer,
      welcome: @room.welcome,
      record: record,
      logoutURL: autoclose_url,
      'meta_description': @room.description.truncate(128, separator: ' '),
    }
    # Send the create request.
    bbb.create_meeting(@room.name, @room.handler, create_options)
  end

  # Perform ends meeting for the current @room.
  def end_meeting
    response = { returncode: 'FAILED' }
    begin
      response = bbb.end_meeting(@room.handler, @room.moderator)
    rescue BigBlueButton::BigBlueButtonException
      # this can be thrown if all participants left (clicked 'x' before pressing the end button)
    end
    response
  end

  # Retrieves meeting info for the current Room.
  def meeting_info
    info = { returncode: 'FAILED' }
    begin
      info = bbb.get_meeting_info(@room.handler, @user)
    rescue BigBlueButton::BigBlueButtonException => e
      logger.info(e.to_s)
    end
    info
  end

  # Checks if the meeting for current @room is running.
  def meeting_running?
    begin
      res = bbb.is_meeting_running?(@room.handler)
    rescue BigBlueButton::BigBlueButtonException => e
      logger.info(e.to_s)
      res = false
    end

    res
  end

  # Fetches all recordings for a room.
  def recordings
    cached_rec = Rails.cache.fetch("#{@room.handler}/#{__method__}")
    return cached_rec unless cached_rec.nil?

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

    recs = res[:recordings].sort_by { |rec| rec[:endTime] }.reverse

    Rails.cache.fetch("#{@room.handler}/#{__method__}", expires_in: 30.minutes) do
      recs
    end

    recs
  end

  def server_running?
    begin
      bbb.get_meeting_info(@room.handler, @user)
    rescue BigBlueButton::BigBlueButtonException => e
      logger.info('We could not find a meeting with that meeting ID')
      return e.to_s
    end

    nil
  end

  # Deletes a recording.
  def delete_recording(record_id)
    Rails.cache.clear
    bbb.delete_recordings(record_id)
  end

  # Publishes a recording.
  def publish_recording(record_id)
    Rails.cache.clear
    bbb.publish_recordings(record_id, true)
  end

  # Unpublishes a recording.
  def unpublish_recording(record_id)
    Rails.cache.clear
    bbb.publish_recordings(record_id, false)
  end

  # Updates a recording.
  def update_recording(record_id, meta)
    Rails.cache.clear
    meta[:recordID] = record_id
    bbb.send_api_request('updateRecordings', meta)
  end

  # Check if the current @user must wait_for_moderator to join the current @room.
  def wait_for_mod?
    return unless @room && @user

    cached_wait = Rails.cache.fetch("#{@room.handler}/#{__method__}")
    return cached_wait unless cached_wait.nil?

    wait = @room.wait_moderator && !@user.moderator?(bigbluebutton_moderator_roles)

    Rails.cache.fetch("#{@room.handler}/#{__method__}", expires_in: 5.minutes) do
      wait
    end

    wait
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

  def bigbluebutton_recording_enabled
    ActiveModel::Type::Boolean.new.cast(Rails.configuration.bigbluebutton_recording_enabled)
  end

  # Helper for converting BigBlueButton dates into the desired format.
  def recording_date(date)
    # NOTE: if we really wanted ordinalization, then we can add an if statement to ordinalize if locale is en.
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
