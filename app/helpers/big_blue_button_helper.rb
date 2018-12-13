module BigBlueButtonHelper

  BIGBLUEBUTTON_ENDPOINT = "http://10.39.81.96/bigbluebutton/" #"http://test-install.blindsidenetworks.com/bigbluebutton/"
  BIGBLUEBUTTON_SECRET = "be2b15dce0e012e6dfea2b66e5b2c95a" #"8cd8ef52e8e101574e400365b55e11a6"
  BIGBLUEBUTTON_MODERATOR_ROLES = "Instructor,Faculty,Teacher,Mentor,Administrator,Admin"

  def bigbluebutton_endpoint
    endpoint = ENV['BIGBLUEBUTTON_ENDPOINT'] || BIGBLUEBUTTON_ENDPOINT
    endpoint += 'api'
    endpoint
  end

  def bigbluebutton_secret
    secret = ENV['BIGBLUEBUTTON_SECRET'] || BIGBLUEBUTTON_SECRET
    secret
  end

  def bigbluebutton_moderator_roles
    (ENV['BIGBLUEBUTTON_MODERATOR_ROLES'] || BIGBLUEBUTTON_MODERATOR_ROLES).split(",")
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

  private

  # Sets a BigBlueButtonApi object for interacting with the API.
  def bbb
    @bbb ||= BigBlueButton::BigBlueButtonApi.new(bigbluebutton_endpoint, bigbluebutton_secret, "0.8")
  end
end
