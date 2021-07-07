# frozen_string_literal: true

require 'user'
require 'bbb_api'

class RoomsController < ApplicationController
  include ApplicationHelper
  include BbbApi
  include BbbAppRooms

  before_action -> {authenticate_with_oauth! :bbbltibroker},
    only: :launch, raise: false
  before_action :set_launch_room, only: %i[launch]

  before_action :find_room, except: %i[launch close]
  before_action :validate_room, except: %i[launch close]
  before_action :find_user
  before_action :find_app_launch, only: %i[launch]

  before_action only: %i[show launch close] do
    authorize_user!(:show, @room)
  end
  before_action only: %i[edit update recording_publish recording_unpublish
                         recording_update recording_delete] do
    authorize_user!(:edit, @room)
  end

  # GET /rooms/1
  def show
    respond_to do |format|
      # TODO: do this also in a worker in the future to speed up this request
      @room.update_recurring_meetings

      @scheduled_meetings = @room.scheduled_meetings.active
                              .order(:start_at).page(params[:page])

      format.html { render :show }
    end
  end

  def recordings
    respond_to do |format|
      @recordings = get_recordings(@room)
      format.html { render :recordings }
    end
  end

  # GET /launch
  def launch
    scheduled_meeting_id = @app_launch.custom_param('scheduled_meeting')
    scheduled_meeting = ScheduledMeeting.find_by_id(scheduled_meeting_id)
    if scheduled_meeting
      redirect_to(external_room_scheduled_meeting_path(@room, scheduled_meeting))
    else
      redirect_to(room_path(@room))
    end
  end

  # GET /rooms/close
  # A simple page that closes itself
  def close
    respond_to do |format|
      format.html { render :autoclose }
    end
  end

  # GET /rooms/:id/recording/:record_id/playback/:playback_type
  def recording_playback
    recording = get_recordings(@room, recordID: params[:record_id]).first
    playback = recording[:playbacks].find { |p| p[:type] == params[:playback_type] }
    playback_url = URI.parse(playback[:url])
    if Rails.application.config.playback_url_authentication
      token = get_recording_token(@room, @user.full_name, params[:record_id])
      playback_url.query = URI.encode_www_form({ token: token })
    end
    redirect_to(playback_url.to_s)
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

  def error
    error_code = params[:code]
    path = room_path(@room)
    redirect_args = [path]

    case error_code
    when 'oauth_error'
      notice = t('default.rooms.error.oauth')
      redirect_args << { notice: notice }
    end
    redirect_to(*redirect_args)
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
      Rails.logger.info "The session is not valid, returning a 403"
      set_error('room', 'forbidden', :forbidden)
      respond_with_error(@error)
      return
    end

    launch_params = session_params['message']
    if launch_params['user_id'] != session['omniauth_auth']['bbbltibroker']['uid']
      Rails.logger.info "The user in the session doesn't match the user in the launch, returning a 403"
      set_error('room', 'forbidden', :forbidden)
      respond_with_error(@error)
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

    remove_old_app_launch

    # Store the data from this launch for easier access
    app_launch = AppLaunch.find_or_create_by(nonce: launch_nonce) do |launch|
      launch.update(
        params: launch_params,
        omniauth_auth: session['omniauth_auth']['bbbltibroker'],
        expires_at: expires_at
      )
    end

    # Use this data only during the launch
    # From now on, take it from the AppLaunch
    session.delete('omniauth_auth')

    # Create/update the room
    local_room_params = app_launch.room_params
    @room = Room.create_with(local_room_params)
              .find_or_create_by(handler: local_room_params[:handler])
    @room.update(local_room_params) if @room.present?

    # Create the user session
    # Keep it as small as possible, most of the data is in the AppLaunch
    set_room_session(
      @room, { launch: launch_nonce }
    )
  end

  # FIX ME
  # Move to a worker in the future
  def remove_old_app_launch
    deleted_launches = 0
    date_limit = Rails.configuration.launch_days_to_delete.days.ago
    query_started = Time.now.utc
    AppLaunch.where('expires_at < ?', date_limit).each do | expired_launch |
      nonce = expired_launch.nonce
      meeting = ScheduledMeeting.where(created_by_launch_nonce: nonce)
      if meeting.empty?
        deleted_launch = AppLaunch.find_by(nonce: nonce).delete
        deleted_launches+= 1
      end
    end
    query_duration = Time.now.utc - query_started
    Rails.logger.info "Removing the old AppLaunches from before #{date_limit}, #{deleted_launches} AppLaunches deleted, in: #{query_duration} seconds"
  end
end
