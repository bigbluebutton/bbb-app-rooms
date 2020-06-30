# frozen_string_literal: true

class SessionsController < ApplicationController
  include ApplicationHelper

  def new; end

  def create
    omniauth_auth = request.env['omniauth.auth']
    omniauth_params = request.env['omniauth.params']

    # Return error if authentication fails
    redirect_to(omniauth_failure_path) && return unless omniauth_auth&.uid

    # As authentication did not fail, initialize the session
    session[omniauth_params['launch_nonce']] = omniauth_auth.to_hash.slice('uid')
    redirect_to(room_launch_url(launch_nonce: omniauth_params['launch_nonce']))
  end

  def failure
    redirect_to(errors_url(500))
  end
end
