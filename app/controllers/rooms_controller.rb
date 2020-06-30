# frozen_string_literal: true

require 'user'
require 'bbb_api'

class RoomsController < ApplicationController
  include ApplicationHelper
  include BbbApi
  include BbbAppRooms

  before_action :authenticate_user!, only: :launch, raise: false #except: %i[close], raise: false
  before_action :set_launch_room, only: %i[launch]

  before_action :find_room, except: %i[launch close index new create]
  before_action :validate_room, except: %i[launch close index new create]
  before_action :find_user, except: %i[close]

  before_action only: %i[show launch close] do
    authorize_user!(:show, @room)
  end
  before_action only: %i[edit update recording_publish recording_unpublish
                         recording_update recording_delete] do
    authorize_user!(:edit, @room)
  end
  before_action only: %i[index new create destroy] do
    authorize_user!(:admin, @room)
  end

  before_action :check_for_cancel, only: %i[create update]

  # GET /rooms
  # GET /rooms.json
  def index
    @rooms = Room.all
  end

  # GET /rooms/1
  # GET /rooms/1.json
  def show
    respond_to do |format|
      if @room
        @recordings = get_recordings(@room)
        @scheduled_meetings = @room.scheduled_meetings.active.order(:start_at)
        format.html { render :show }
        format.json { render :show, status: :ok, location: @room }
      else
        format.html { render 'shared/error', status: @error[:status] }
        format.json { render json: { error: @error[:message] }, status: @error[:status] }
      end
    end
  end

  # GET /rooms/new
  def new
    @room = Room.new
  end

  # GET /rooms/1/edit
  def edit; end

  # POST /rooms
  # POST /rooms.json
  def create
    @room = Room.new(room_params)
    respond_to do |format|
      if @room.save
        format.html { redirect_to @room, notice: t('default.room.created') }
        format.json { render :show, status: :created, location: @room }
      else
        format.html { render :new }
        format.json { render json: @error, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /rooms/1
  # PATCH/PUT /rooms/1.json
  def update
    respond_to do |format|
      if @room.update(room_params)
        format.html { redirect_to @room, notice: t('default.room.updated') }
        format.json { render :show, status: :ok, location: @room }
      else
        format.html { render :edit }
        format.json { render json: @error, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /rooms/1
  # DELETE /rooms/1.json
  def destroy
    @room.destroy
    respond_to do |format|
      format.html { redirect_to rooms_url, notice: t('default.room.destroyed') }
      format.json { head :no_content }
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
    unpublish_recording(params[:record_id])
    redirect_to(room_path(@room))
  end

  # POST /rooms/:id/recording/:record_id/publish
  def recording_publish
    publish_recording(params[:record_id])
    redirect_to(room_path(@room))
  end

  # POST /rooms/:id/recording/:record_id/update
  def recording_update
    if params[:setting] == "rename_recording"
      update_recording(params[:record_id], "meta_name" => params[:record_name])
    elsif params[:setting] == "describe_recording"
      update_recording(params[:record_id], "meta_description" => params[:record_description])
    end
    redirect_to(room_path(@room))
  end

  # POST /rooms/:id/recording/:record_id/delete
  def recording_delete
    delete_recording(params[:record_id])
    redirect_to(room_path(@room))
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
      set_room_error('forbidden', :forbidden)
      return
    end

    launch_params = session_params['message']
    unless launch_params['user_id'] == session['omniauth_auth']['uid']
      Rails.logger.info "The user in the session doesn't match the user in the launch, returning a 401"
      set_room_error('forbidden', :forbidden)
      return
    end

    expires_at = Rails.configuration.session_duration_mins.from_now

    # Store the data from this launch for easier access
    app_launch = AppLaunch.find_or_create_by(nonce: launch_nonce) do |launch|
      launch.update(
        params: launch_params,
        omniauth_auth: session['omniauth_auth'],
        expires_at: expires_at
      )
    end

    # TODO: temporary for debug
    puts "----------------------- LAUNCHING"
    puts session['omniauth_auth'].inspect
    puts "-----------------------"
    puts app_launch.inspect
    puts "-----------------------"

    # Use this data only during the launch
    # From now on, take it from the AppLaunch
    session.delete('omniauth_auth')

    # Create/update the room
    local_room_params = app_launch.room_params
    @room = Room.find_or_create_by(handler: local_room_params[:handler]) do |room|
      room.update(params.permit.merge(local_room_params))
    end

    # Create the user session
    # Keep it as small as possible, most of the data is in the AppLaunch
    session[@room.handler] = {
      launch: launch_nonce,
      expires: expires_at
    }.stringify_keys # they will be strings in future calls, so make them strings already
  end

  def room_params
    params.require(:room).permit(:name, :description, :welcome, :moderator, :viewer,
                                 :recording, :wait_moderator, :all_moderators)
  end

  def check_for_cancel
    redirect_to(@room) if params[:cancel]
  end
end
