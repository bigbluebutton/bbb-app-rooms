module BigBlueButtonHelper

  BIGBLUEBUTTON_ENDPOINT = "http://test-install.blindsidenetworks.com/bigbluebutton/"
  BIGBLUEBUTTON_SECRET = "8cd8ef52e8e101574e400365b55e11a6"
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
    bbb ||= BigBlueButton::BigBlueButtonApi.new(bigbluebutton_endpoint, bigbluebutton_secret, "0.8", false)
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
    })
    role = (@user.moderator?(bigbluebutton_moderator_roles) || @room.all_moderators) ? 'moderator' : 'viewer'
    bbb.join_meeting_url(@room.handler, @user.username(t("default.bigbluebutton.#{role}")), @room.attributes[role])
  end

end
