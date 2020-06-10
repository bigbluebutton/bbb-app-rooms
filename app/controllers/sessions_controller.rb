class SessionsController < ApplicationController
  include ApplicationHelper

  def new
    puts ">>>>>>>>>> SessionsController:new"
  end

  def create
    puts ">>>>>>>>>> SessionsController:create"
    omniauth_auth = request.env["omniauth.auth"]
    omniauth_params = request.env["omniauth.params"]

    # Return error if authentication fails
    redirect_to omniauth_failure_path and return unless omniauth_auth && omniauth_auth.uid

    # As authentication did not fail, initialize the session
    session['omniauth_auth'] = omniauth_auth
    redirector = room_launch_url(launch_nonce: omniauth_params['launch_nonce'])
    puts ">>>>> redirects to #{redirector}"
    redirect_to redirector
  end

  def failure
    puts ">>>>>>>>>> SessionsController:failure"
  end

end
