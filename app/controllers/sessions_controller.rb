class SessionsController < ApplicationController
  include ApplicationHelper

  def new
  end

  def create
    omniauth_auth = request.env["omniauth.auth"]
    omniauth_params = request.env["omniauth.params"]

    # Return error if authentication fails
    redirect_to omniauth_failure_path and return unless omniauth_auth && omniauth_auth.uid

    # As authentication did not fail, initialize the session
    session['omniauth_auth'] = omniauth_auth
    redirector = room_launch_url(launch_nonce: omniauth_params['launch_nonce'])
    redirect_to redirector
  end

  def failure
  end

end
