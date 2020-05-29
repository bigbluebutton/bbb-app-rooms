class SessionsController < ApplicationController
  include ApplicationHelper

  def new
    cookies['launch_params'] = params.except(:controller, :action).to_json
    redirect_to omniauth_authorize_url(:bbbltibroker)
  end

  def create
    auth = request.env["omniauth.auth"]

    # Return error if authentication fails
    redirect_to omniauth_failure_path and return unless auth && auth.uid

    # As authentication did not fail, initialize the session
    session[:uid] = auth.uid
    redirect_to "#{room_launch_url}"
  end

  def failure
  end

end
