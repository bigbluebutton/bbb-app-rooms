# frozen_string_literal: true

module BbbApi
  def wait_for_mod?(scheduled_meeting, user)
    return unless scheduled_meeting and user
    scheduled_meeting.check_wait_moderator &&
      !user.moderator?(Abilities.moderator_roles) &&
      !scheduled_meeting.check_all_moderators
  end

  def mod_in_room?(scheduled_meeting)
    room = scheduled_meeting.room
    bbb(room).is_meeting_running?(scheduled_meeting.meeting_id)
  end

  def join_api_url(scheduled_meeting, user)
    return unless scheduled_meeting.present? && user.present?

    room = scheduled_meeting.room

    unless bbb(room).is_meeting_running?(scheduled_meeting.meeting_id)
      bbb(room).create_meeting(
        scheduled_meeting.name,
        scheduled_meeting.meeting_id,
        scheduled_meeting.create_options(user).merge(
          { logoutURL: autoclose_url }
        )
      )
    end

    is_moderator = user.moderator?(Abilities.moderator_roles) ||
                   scheduled_meeting.check_all_moderators
    role = is_moderator ? 'moderator' : 'viewer'
    bbb(room, false).join_meeting_url(
      scheduled_meeting.meeting_id,
      user.username(t("default.bigbluebutton.#{role}")),
      room.attributes[role]
    )
  end

  def external_join_api_url(scheduled_meeting, full_name)
    return unless scheduled_meeting.present? && full_name.present?

    room = scheduled_meeting.room
    bbb(room, false).join_meeting_url(
      scheduled_meeting.meeting_id,
      full_name,
      room.attributes['viewer'],
      { guest: true }
    )
  end

  # Fetches all recordings for a room.
  def get_recordings(room)
    res = bbb(room).get_recordings(room.params_for_get_recordings)

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

  # Helper for converting BigBlueButton dates into the desired format.
  def recording_date(date)
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

  # Deletes a recording from a room.
  def delete_recording(room, record_id)
    bbb(room).delete_recordings(record_id)
  end

  # Publishes a recording for a room.
  def publish_recording(room, record_id)
    bbb(room).publish_recordings(record_id, true)
  end

  # Unpublishes a recording for a room.
  def unpublish_recording(room, record_id)
    bbb(room).publish_recordings(record_id, false)
  end

  # Update recording for a room.
  def update_recording(room, record_id, meta)
    meta[:recordID] = record_id
    bbb(room).send_api_request('updateRecordings', meta)
  end

  private

  # Sets a BigBlueButtonApi object for interacting with the API.
  def bbb(room, internal = true)
    # TODO: consumer_key should never be blank, keeping this condition here just while
    # all rooms migrate to the new format. Remove it after a while.
    consumer_key = if room.consumer_key.blank?
                     room.last_launch.try(:oauth_consumer_key)
                   else
                     room.consumer_key
                   end
    server = BigbluebuttonServer.find_by(key: consumer_key)

    if server.present?
      Rails.logger.info "Found the server:#{server.domain} secret:#{server.secret[0..7]} "\
                        "for the room:#{room.to_param} " \
                        "using the consumer_key:#{consumer_key}"

      endpoint = if internal && !server.internal_endpoint.blank?
                   server.internal_endpoint
                 else
                   server.endpoint
                 end
      secret = server.secret
    else
      Rails.logger.info "Using the default server for the room:#{room.to_param}, " \
                        "couldn't find one for consumer_key:#{consumer_key}"

      ep = Rails.configuration.bigbluebutton_endpoint
      iep = Rails.configuration.bigbluebutton_endpoint_internal
      endpoint = internal && !iep.blank? ? iep : ep
      secret = Rails.configuration.bigbluebutton_secret
    end

    BigBlueButton::BigBlueButtonApi.new(
      remove_slash(fix_bbb_endpoint_format(endpoint)), secret, "0.9", "true"
    )
  end

  # Fixes BigBlueButton endpoint ending.
  def fix_bbb_endpoint_format(url)
    # Fix endpoint format only if required.
    url += '/' unless url.ends_with?('/')
    url += 'api/' if url.ends_with?('bigbluebutton/')
    url += 'bigbluebutton/api/' unless url.ends_with?('bigbluebutton/api/')
    url
  end

  # Removes trailing forward slash from a URL.
  def remove_slash(str)
    str.nil? ? nil : str.chomp('/')
  end
end
