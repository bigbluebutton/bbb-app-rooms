module BigBlueButtonHelper
  def bigbluebutton_endpoint
    Rails.configuration.bigbluebutton_endpoint
  end

  def bigbluebutton_secret
    Rails.configuration.bigbluebutton_secret
  end

  def bigbluebutton_moderator_roles
    Rails.configuration.bigbluebutton_moderator_roles.split(',')
  end

  def fix_bbb_endpoint_format(url)
    # Fix endpoint format only if required.
    url += "/" unless url.ends_with?('/')
    url += "api/" if url.ends_with?('bigbluebutton/')
    url += "bigbluebutton/api/" unless url.ends_with?('bigbluebutton/api/')
    url
  end

  def wait_for_mod?(scheduled_meeting, user)
    return unless scheduled_meeting and user
    scheduled_meeting.wait_moderator && !user.moderator?(bigbluebutton_moderator_roles)
  end

  def mod_in_room?(scheduled_meeting)
    bbb.is_meeting_running?(scheduled_meeting.meeting_id)
  end

  def join_meeting_url(scheduled_meeting, user)
    return unless scheduled_meeting.present? && user.present?
    return unless check_bbb

    room = scheduled_meeting.room
    bbb.create_meeting(scheduled_meeting.name, scheduled_meeting.meeting_id, {
      :moderatorPW => room.moderator,
      :attendeePW => room.viewer,
      :welcome => room.welcome,
      :record => scheduled_meeting.recording,
      :logoutURL => autoclose_url,
      :"meta_description" => room.description,
    })

    is_moderator = user.moderator?(bigbluebutton_moderator_roles) || scheduled_meeting.all_moderators
    role = is_moderator ? 'moderator' : 'viewer'
    bbb.join_meeting_url(
      scheduled_meeting.meeting_id,
      user.username(t("default.bigbluebutton.#{role}")),
      room.attributes[role]
    )
  end

  def external_join_meeting_url(scheduled_meeting, full_name)
    return unless scheduled_meeting.present? && full_name.present?
    return unless check_bbb

    room = scheduled_meeting.room
    bbb.join_meeting_url(
      scheduled_meeting.meeting_id,
      full_name,
      room.attributes['viewer']
    )
  end

  # Fetches all recordings for a room.
  def get_recordings(room)
    res = bbb.get_recordings(meetingID: room.ids_for_get_recordings)

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
    valid_playbacks = playbacks.reject { |p| p[:type] == "statistics" }
    return "0 min" if valid_playbacks.empty?

    len = valid_playbacks.first[:length]
    if len > 60
      "#{(len / 60).round} hrs"
    elsif len == 0
      "< 1 min"
    else
      "#{len} min"
    end
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
    bbb.send_api_request("updateRecordings", meta)
  end

  private

  # Sets a BigBlueButtonApi object for interacting with the API.
  def bbb
    @bbb ||= BigBlueButton::BigBlueButtonApi.new(
      remove_slash(fix_bbb_endpoint_format(bigbluebutton_endpoint)),
      bigbluebutton_secret, "0.9", "true"
    )
  end

  def check_bbb
    unless bbb
      @error = {
        key: t('error.bigbluebutton.invalidrequest.code'),
        message:  t('error.bigbluebutton.invalidrequest.message'),
        suggestion: t('error.bigbluebutton.invalidrequest.suggestion'),
        status: :internal_server_error
      }
      false
    else
      true
    end
  end

  # Removes trailing forward slash from a URL.
  def remove_slash(s)
    s.nil? ? nil : s.chomp("/")
  end
end
