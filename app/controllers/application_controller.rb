# frozen_string_literal: true

require 'bigbluebutton_api'

class ApplicationController < ActionController::Base
  before_action :set_current_locale
  before_action :set_timezone
  before_action :allow_iframe_requests

  before_action do
    Rails.logger.info "----------------------------- DEBUG"
    Rails.logger.info session['omniauth_auth'].inspect
    if @room.present? && session.key?(@room.handler)
      Rails.logger.info session[@room.handler].inspect
    else
      Rails.logger.info '-- NO ROOM'
    end
    Rails.logger.info "-----------------------------"
  end

  # Check if the user authentication exists in the session and is valid (didn't expire).
  # On launch, go get the credentials needed.
  def authenticate_user
    return true unless omniauth_provider?(:bbbltibroker)

    # Assume user authenticated if session[:omaniauth_auth] is set
    return true if session['omniauth_auth'] &&
                   Time.now.to_time.to_i < session['omniauth_auth']["credentials"]["expires_at"].to_i

    if params['action'] == 'launch'
      redirector = omniauth_authorize_path(:bbbltibroker, launch_nonce: params[:launch_nonce])
      redirect_to(redirector) and return true
    end

    false
  end

  # Same as authenticate_user but returns a 401 if the user is not authenticated.
  def authenticate_user!
    redirect_to(errors_path(401)) unless authenticate_user
  end

  # Find the user info in the session.
  # It's stored scoped by the room the user is accessing.
  def find_user
    if @room.present? && session.key?(@room.handler)
      @user = BbbAppRooms::User.new(session[@room.handler]['user_params'])
    end
  end

  def authorize_user!(action, resource)
    redirect_to errors_path(401) unless Abilities.can?(@user, action, resource)
  end

  def check_room(only_presence = false)
    # Exit with error if room was not found
    unless @room
      set_room_error('notfound', :not_found)
      return false
    end

    Rails.logger.info "----------------------------- ROOM"
    if @room.present? && session.key?(@room.handler)
      Rails.logger.info session[@room.handler].inspect
    end
    Rails.logger.info "-----------------------------"


    unless only_presence
      # Exit with error by re-setting the room to nil if the session for the room.handler is not set
      expired = session[@room.handler].blank? ||
                session[@room.handler]['expires'].to_time <= Time.zone.now.to_time
      if expired
        set_room_error('forbidden', :forbidden)
        return false
      end
    end

    true
  end

  # Finds the room and checks if it's present
  def find_room
    find_room_internal(true)
  end

  # Finds the room, checks if it's present and if it's valid (session not expired)
  def find_and_validate_room
    find_room_internal(false)
  end

  def set_room_error(error, status)
    @room = @user = nil
    @error = {
      key: t("error.room.#{error}.code"),
      message: t("error.room.#{error}.message"),
      suggestion: t("error.room.#{error}.suggestion"),
      status: status
    }
  end

  private

  def set_current_locale
    locale = nil

    # try to get the locale from the LTI launch, otherwise use the browser's
    if @user.present? && !@user.locale.blank?
      locale = @user.locale
    else
      locale = browser.accept_language.first.try(:code)
    end

    case locale
    when /^pt/
      I18n.locale = locale
    else
      I18n.locale = 'en' # fallback
    end
    response.set_header("Content-Language", I18n.locale)
  end

  def set_timezone
    tz = ActiveSupport::TimeZone[Rails.application.config.default_timezone]
    tz = ActiveSupport::TimeZone['UTC'] if tz.nil?
    Time.zone = tz
  end

  def allow_iframe_requests
    response.headers.delete('X-Frame-Options')
  end

  def find_room_internal(only_presence)
    @room = if params.key?(:room_id)
              Room.from_param(params[:room_id])
            else
              Room.from_param(params[:id])
            end

    # render the default error, aborts the rest of the execution if called in a before_action
    unless check_room(only_presence)
      respond_to do |format|
        format.html { render 'shared/error', status: @error[:status] }
      end
    end
  end
end
