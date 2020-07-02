# frozen_string_literal: true

require 'bbb_api'

class SessionsController < ApplicationController
  include ApplicationHelper
  include BbbApi

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

    # Pull the Launch request_parameters
    bbbltibroker_url = omniauth_bbbltibroker_url("/api/v1/sessions/#{@launch_nonce}")
    Rails.logger.info "Making a session request to #{bbbltibroker_url}"
    session_params = JSON.parse(
      RestClient.get(
        bbbltibroker_url,
        'Authorization' => "Bearer #{omniauth_client_token(omniauth_bbbltibroker_url)}"
      )
    )

    launch = AppLaunch.new(params: session_params['message'])
    @room = Room.find_by(handler: launch&.resource_handler) if launch.present?
    @meeting = nil

    if @room.present?
      meetings = @room.next_meetings
      meetings.each do |meeting|
        if mod_in_room?(meeting)
          @meeting = meeting
          break
        end
      end
      @meeting = meetings.first if @meeting.nil?
    end
  end
end
