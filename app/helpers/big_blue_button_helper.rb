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

  # Sets a BigBlueButtonApi object for interacting with the API.
  def bbb
    @bbb ||= if Rails.configuration.loadbalancer_configured
      lb_user = retrieve_loadbalanced_credentials(owner.provider)
      BigBlueButton::BigBlueButtonApi.new(remove_slash(lb_user["apiURL"]), lb_user["secret"], "0.8")
    else
      BigBlueButton::BigBlueButtonApi.new(remove_slash(bigbluebutton_endpoint), bigbluebutton_secret, "0.8")
    end
  end

  # Removes trailing forward slash from a URL.
  def remove_slash(s)
    s.nil? ? nil : s.chomp("/")
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
    })
    role = (@user.moderator?(bigbluebutton_moderator_roles) || @room.all_moderators) ? 'moderator' : 'viewer'
    bbb.join_meeting_url(@room.handler, @user.username(t("default.bigbluebutton.#{role}")), @room.attributes[role])
  end
end
