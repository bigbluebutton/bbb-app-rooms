# frozen_string_literal: true

require 'user'
require 'bbb_api'

class RoomsController < ApplicationController
  include ApplicationHelper
  include BbbApi
  include BbbAppRooms

  before_action :authenticate_user!, only: :launch, raise: false
  before_action :set_launch_room, only: %i[launch]

  before_action :find_room, except: %i[launch close]
  before_action :validate_room, except: %i[launch close]
  before_action :find_user, except: %i[close]

  before_action only: %i[show launch close] do
    authorize_user!(:show, @room)
  end
  before_action only: %i[edit update recording_publish recording_unpublish
                         recording_update recording_delete] do
    authorize_user!(:edit, @room)
  end

  # GET /rooms/1
  # GET /rooms/1.json
  def show
    respond_to do |format|
      if @room
        @scheduled_meetings = @room.scheduled_meetings.active.order(:start_at)
        format.html { render :show }
        format.json { render :show, status: :ok, location: @room }
      else
        format.html { render 'shared/error', status: @error[:status] }
        format.json { render json: { error: @error[:message] }, status: @error[:status] }
      end
    end
  end

  def recordings
    respond_to do |format|
      if @room
        @recordings = get_recordings(@room)
        format.html { render :recordings }
      else
        format.html { render 'shared/error', status: @error[:status] }
      end
    end
  end

  # GET /launch
  # GET /launch.json?
  def launch
    redirect_to(room_path(@room))
  end

  # GET /rooms/close
  # A simple page that closes itself
  def close
    respond_to do |format|
      format.html { render :autoclose }
    end
  end

  # POST /rooms/:id/recording/:record_id/unpublish
  def recording_unpublish
    unpublish_recording(@room, params[:record_id])
    redirect_to(recordings_room_path(@room))
  end

  # POST /rooms/:id/recording/:record_id/publish
  def recording_publish
    publish_recording(@room, params[:record_id])
    redirect_to(recordings_room_path(@room))
  end

  # POST /rooms/:id/recording/:record_id/update
  def recording_update
    if params[:setting] == "rename_recording"
      update_recording(@room, params[:record_id], "meta_name" => params[:record_name])
    elsif params[:setting] == "describe_recording"
      update_recording(@room, params[:record_id], "meta_description" => params[:record_description])
    end
    redirect_to(recordings_room_path(@room))
  end

  # POST /rooms/:id/recording/:record_id/delete
  def recording_delete
    delete_recording(@room, params[:record_id])
    redirect_to(recordings_room_path(@room))
  end

  helper_method :recordings, :recording_date, :recording_length

  private

  def set_launch_room
    launch_nonce = params['launch_nonce']

    # Pull the Launch request_parameters
    bbbltibroker_url = omniauth_bbbltibroker_url("/api/v1/sessions/#{launch_nonce}")
    Rails.logger.info "Making a session request to #{bbbltibroker_url}"
    session_params = JSON.parse(
      RestClient.get(
        bbbltibroker_url,
        'Authorization' => "Bearer #{omniauth_client_token(omniauth_bbbltibroker_url)}"
      )
    )

    unless session_params['valid']
      Rails.logger.info "The session is not valid, returning a 401"
      set_error('room', 'forbidden', :forbidden)
      return
    end

    launch_params = session_params['message']
    unless launch_params['user_id'] == session['omniauth_auth']['uid']
      Rails.logger.info "The user in the session doesn't match the user in the launch, returning a 401"
      set_error('room', 'forbidden', :forbidden)
      return
    end

    bbbltibroker_url = omniauth_bbbltibroker_url("/api/v1/sessions/#{launch_nonce}/invalidate")
    Rails.logger.info "Making a session request to #{bbbltibroker_url}"
    session_params = JSON.parse(
      RestClient.get(
        bbbltibroker_url,
        'Authorization' => "Bearer #{omniauth_client_token(omniauth_bbbltibroker_url)}"
      )
    )

    expires_at = Rails.configuration.launch_duration_mins.from_now

    # Store the data from this launch for easier access
    app_launch = AppLaunch.find_or_create_by(nonce: launch_nonce) do |launch|
      launch.update(
        params: launch_params,
        omniauth_auth: session['omniauth_auth'],
        expires_at: expires_at
      )
    end

    # Use this data only during the launch
    # From now on, take it from the AppLaunch
    session.delete('omniauth_auth')

    # Create/update the room
    local_room_params = app_launch.room_params
    @room = Room.find_or_create_by(handler: local_room_params[:handler]) do |room|
      room.update(local_room_params)
    end

    # Create the user session
    # Keep it as small as possible, most of the data is in the AppLaunch
    set_room_session(
      @room, { launch: launch_nonce }
    )
  end
end
