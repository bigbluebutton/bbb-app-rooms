require 'bigbluebutton_api'

class ApplicationController < ActionController::Base
  def authenticate_user!
    return unless omniauth_provider?(:bbbltibroker)
    # Assume user authenticated if session[:omaniauth_auth] is set
    return if session['omniauth_auth'] && Time.now.to_time.to_i < session['omniauth_auth']["credentials"]["expires_at"].to_i
    session[:callback] = request.original_url
    if params['action'] == 'launch'
      redirector = omniauth_authorize_path(:bbbltibroker, launch_nonce: params[:launch_nonce])
      redirect_to redirector and return
    end
    redirect_to errors_path(401)
  end

  def check_room
    # Exit with error if room was not found
    set_error('notfound', :not_found) and return false unless @room

    # Exit with error by re-setting the room to nil if the session for the room.handler is not set
    expired = session[@room.handler].blank? ||
              session[@room.handler]['expires'].to_time <= Time.now.to_time
    set_error('forbidden', :forbidden) and return false if expired

    true
  end

  def find_user
    @user = User.find_by(uid: session['omniauth_auth']['uid'])
  end
end
