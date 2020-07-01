# frozen_string_literal: true

class SessionsController < ApplicationController
  include ApplicationHelper

  def new; end

  def create
    omniauth_auth = request.env['omniauth.auth']
    omniauth_params = request.env['omniauth.params']
    Rails.logger.info "Omniauth authentication information auth=#{omniauth_auth.inspect} " \
                      "params=#{omniauth_params.inspect}"

    # Return error if authentication fails
    unless omniauth_auth&.uid
      Rails.logger.info "Authentication failed, redirecting to #{omniauth_retry_path(omniauth_params)}"
      redirect_to(omniauth_retry_path(omniauth_params)) && return
    end

    # As authentication did not fail, initialize the session
    session['omniauth_auth'] = omniauth_auth
    redirect_to(room_launch_url(launch_nonce: omniauth_params['launch_nonce']))
  end

  def failure
    # TODO: there are different types of errors, not all require a retry
    redirect_to(
      omniauth_retry_path(provider: params['provider'], launch_nonce: params['launch_nonce'])
    )
  end

  def retry
    @launch_nonce = params['launch_nonce']
  end
end
