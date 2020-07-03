# frozen_string_literal: true

require 'bbb_api'

class SessionsController < ApplicationController
  include ApplicationHelper
  include BbbApi

  def new; end

  def create
    omniauth_auth = request.env['omniauth.auth']
    Rails.logger.info "Omniauth authentication information auth=#{omniauth_auth.inspect} " # \

    # Return error if authentication fails
    unless omniauth_auth&.uid
      Rails.logger.info "Authentication failed, redirecting to #{omniauth_retry_path(params)}"
      redirect_to(omniauth_retry_path(params)) && return
    end

    # As authentication did not fail, initialize the session
    session['omniauth_auth'] = omniauth_auth
    redirect_to(
      room_launch_url(
        launch_nonce: params['launch_nonce'], provider: params['provider'], session_set: true
      )
    )
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
