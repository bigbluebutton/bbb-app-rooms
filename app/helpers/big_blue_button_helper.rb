module BigBlueButtonHelper
  def bigbluebutton_endpoint
    url = Rails.configuration.bigbluebutton_endpoint
    # Fix endpoint format if required.
    url += "/" unless url.ends_with?('/')
    url += "api/" if url.ends_with?('bigbluebutton/')
    url += "bigbluebutton/api/" unless url.ends_with?('bigbluebutton/api/')
    url
  end

  def bigbluebutton_secret
    Rails.configuration.bigbluebutton_secret
  end

  def bigbluebutton_moderator_roles
    Rails.configuration.bigbluebutton_moderator_roles.split(',')
  end

  def wait_for_mod?
    return unless @room and @user
    @room.wait_moderator && ! @user.moderator?(bigbluebutton_moderator_roles)
  end

  def mod_in_room?
    bbb.is_meeting_running?(@room.handler)
  end

  def join_meeting_url
    return unless @room and @user
    unless bbb
      @error = {
        key: t('error.bigbluebutton.invalidrequest.code'),
        message:  t('error.bigbluebutton.invalidrequest.message'),
        suggestion: t('error.bigbluebutton.invalidrequest.suggestion'),
        status: :internal_server_error
      }
      return
    end
    bbb.create_meeting(@room.name, @room.handler, {
      :moderatorPW => @room.moderator,
      :attendeePW => @room.viewer,
      :welcome => @room.welcome,
      :record => @room.recording,
      :logoutURL => autoclose_url,
      :"meta_description" => @room.description,
    })
    role = (@user.moderator?(bigbluebutton_moderator_roles) || @room.all_moderators) ? 'moderator' : 'viewer'
    bbb.join_meeting_url(@room.handler, @user.username(t("default.bigbluebutton.#{role}")), @room.attributes[role])
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
    @bbb ||= BigBlueButton::BigBlueButtonApi.new(remove_slash(bigbluebutton_endpoint), bigbluebutton_secret, "0.9", "true")
  end

  # Removes trailing forward slash from a URL.
  def remove_slash(s)
    s.nil? ? nil : s.chomp("/")
  end
end
