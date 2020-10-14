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

    provider = params['provider']
    session['omniauth_auth'] ||= {}
    session['omniauth_auth'][provider] = omniauth_auth

    omniauth_params = request.env['omniauth.params']
    if provider == 'brightspace'
      scheduled_meeting_id = omniauth_params['scheduled_meeting']
      redirect_to brightspace_send_calendar_event_url scheduled_meeting_id
    elsif provider == 'bbbltibroker'
      redirect_to(
        room_launch_url(
          launch_nonce: params['launch_nonce'], provider: provider, session_set: true
        )
      )
    end
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
