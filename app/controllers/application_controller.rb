# frozen_string_literal: true

require 'bigbluebutton_api'

class ApplicationController < ActionController::Base
  before_action :set_current_locale
  before_action :set_timezone
  before_action :allow_iframe_requests

  def authenticate_user!
    return unless omniauth_provider?(:bbbltibroker)

    # Assume user authenticated if session[:omaniauth_auth] is set
    return if session['omniauth_auth'] &&
              Time.now.to_time.to_i < session['omniauth_auth']["credentials"]["expires_at"].to_i

    session[:callback] = request.original_url
    if params['action'] == 'launch'
      redirector = omniauth_authorize_path(:bbbltibroker, launch_nonce: params[:launch_nonce])
      redirect_to(redirector) and return
    end

    redirect_to(errors_path(401))
  end

  def authorize_user!(action, resource)
    redirect_to errors_path(401) unless Abilities.can?(@user, action, resource)
  end

  def check_room
    # Exit with error if room was not found
    unless @room
      set_room_error('notfound', :not_found)
      return false
    end

    # Exit with error by re-setting the room to nil if the session for the room.handler is not set
    expired = session[@room.handler].blank? ||
              session[@room.handler]['expires'].to_time <= Time.zone.now.to_time
    if expired
      set_room_error('forbidden', :forbidden)
      return false
    end

    true
  end

  def find_room
    @room = if params.key?(:room_id)
              Room.from_param(params[:room_id])
            else
              Room.from_param(params[:id])
            end

    # render the default error, aborts the rest of the execution if called in a before_action
    unless check_room
      respond_to do |format|
        format.html { render 'shared/error', status: @error[:status] }
      end
    end
  end

  def find_user
    # @user = User.find_by(uid: session['omniauth_auth']['uid'])
    @user = BbbAppRooms::User.new(session[@room.handler]['user_params'])
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
    al = browser.accept_language.first
    case al.code
    when 'pt'
      I18n.locale = al.code
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
