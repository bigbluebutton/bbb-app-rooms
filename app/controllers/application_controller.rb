# frozen_string_literal: true

require 'bigbluebutton_api'

class ApplicationController < ActionController::Base
  before_action :set_current_locale
  before_action :set_timezone
  before_action :allow_iframe_requests

  # Check if the user authentication exists in the session and is valid (didn't expire).
  # On launch, go get the credentials needed.
  def authenticate_user!
    unless omniauth_provider?(:bbbltibroker)
      Rails.logger.info "Provider is not bbbltibroker"
      return true
    end

    # Assume user authenticated if session[:omaniauth_auth] is set
    if session['omniauth_auth'] &&
       Time.now.to_time.to_i < session['omniauth_auth']["credentials"]["expires_at"].to_i
      Rails.logger.info "Found a valid omniauth_auth in the session, user already authenticated"
      return true
    end

    Rails.logger.info "Redirecting to the authorization route"
    redirector = omniauth_authorize_path(:bbbltibroker, launch_nonce: params[:launch_nonce])
    redirect_to(redirector) and return true
  end

  # Find the user info in the session.
  # It's stored scoped by the room the user is accessing.
  def find_user
    if @room.present? && session.key?(@room.handler)
      user_params = AppLaunch.find_by(nonce: session[@room.handler]['launch']).user_params
      @user = BbbAppRooms::User.new(user_params)
      Rails.logger.info "Found the user #{@user.email} (#{@user.uid}, #{@user.launch_nonce})"
    end

    # TODO: temporary for debug
    Rails.logger.info "----------------------------- FOUND USER"
    Rails.logger.info @user.inspect
    if @room.present? && session.key?(@room.handler)
      Rails.logger.info session[@room.handler].inspect
    end
    Rails.logger.info "-----------------------------"

    # TODO: check expiration here?
    # return true if session['omniauth_auth'] &&
    #                Time.now.to_time.to_i < session['omniauth_auth']["credentials"]["expires_at"].to_i

  end

  def authorize_user!(action, resource)
    redirect_to errors_path(401) unless Abilities.can?(@user, action, resource)
  end

  def find_room
    @room = if params.key?(:room_id)
              Room.from_param(params[:room_id])
            else
              Room.from_param(params[:id])
            end

    # Exit with error if room was not found
    unless @room.present?
      Rails.logger.info "Couldn't find a room in the URL, returning 404"
      set_room_error('notfound', :not_found)
      respond_to do |format|
        format.html { render 'shared/error', status: @error[:status] }
      end
      return false
    end

    # TODO: temporary for debug
    Rails.logger.info "----------------------------- FOUND ROOM"
    Rails.logger.info @room.handler
    if @room.present? && session.key?(@room.handler)
      Rails.logger.info session[@room.handler].inspect
    end
    Rails.logger.info "-----------------------------"
  end

  def validate_room
    # Exit with error by re-setting the room to nil if the session for the room.handler is not set
    expired = session[@room.handler].blank? ||
              session[@room.handler]['expires'].to_time <= Time.zone.now.to_time
    if expired
      Rails.logger.info "The session set for this room expired: #{session[@room.handler].inspect}"
      set_room_error('forbidden', :forbidden)
      respond_to do |format|
        format.html { render 'shared/error', status: @error[:status] }
      end
      return false
    end
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
end
