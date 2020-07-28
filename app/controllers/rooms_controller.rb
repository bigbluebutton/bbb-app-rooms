# frozen_string_literal: true

require 'user'
require 'bbb_api'

class RoomsController < ApplicationController
  include ApplicationHelper
  include BbbApi
  include BbbAppRooms

  before_action :authenticate_user!, except: %i[meeting_close], raise: false
  before_action :set_launch, only: %i[launch]
  before_action :set_room, only: %i[show edit update destroy meeting_join meeting_end meeting_close]
  before_action :check_for_cancel, only: [:create, :update]
  before_action :allow_iframe_requests

  # GET /rooms/1
  # GET /rooms/1.json
  def show
    respond_to do |format|
      if @room
        format.html { render :show }
        format.json { render :show, status: :ok, location: @room }
      else
        format.html { render :error, status: @error[:status] }
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
        format.html { redirect_to room_path(@room, launch_nonce: params[:launch_nonce]), notice: t('default.room.updated') }
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
    redirect_to(room_path(@room.id, launch_nonce: params['launch_nonce']))
  end

  # POST /rooms/:id/meeting/join
  # POST /rooms/:id/meeting/join.json
  def meeting_join
    # make user wait until moderator is in room
    wait = wait_for_mod? && !mod_in_room?
    NotifyRoomWatcherJob.set(wait: 5.seconds).perform_later(@room) unless wait
    render(json: { wait_for_mod: wait, meeting: join_meeting_url }, status: :ok)
  end

  # GET /rooms/:id/meeting/end
  # GET /rooms/:id/meeting/end.json
  def meeting_end; end

  # GET /rooms/:id/meeting/close
  def meeting_close
    respond_to do |format|
      format.html { render :autoclose }
    end
  end

  # POST /rooms/:id/recording/:record_id/unpublish
  def recording_unpublish
    unpublish_recording(params[:record_id])
    redirect_to(room_path(params[:id], launch_nonce: params[:launch_nonce]))
  end

  # POST /rooms/:id/recording/:record_id/publish
  def recording_publish
    publish_recording(params[:record_id])
    redirect_to(room_path(params[:id], launch_nonce: params[:launch_nonce]))
  end

  # POST /rooms/:id/recording/:record_id/update
  def recording_update
    if params[:setting] == 'rename_recording'
      update_recording(params[:record_id], 'meta_name' => params[:record_name])
    elsif params[:setting] == 'describe_recording'
      update_recording(params[:record_id], 'meta_description' => params[:record_description])
    end
    redirect_to(room_path(params[:id], launch_nonce: params[:launch_nonce]))
  end

  # POST /rooms/:id/recording/:record_id/delete
  def recording_delete
    delete_recording(params[:record_id])
    redirect_to(room_path(params[:id], launch_nonce: params[:launch_nonce]))
  end

  helper_method :recordings, :recording_date, :recording_length, :bigbluebutton_moderator_roles

  private

  def set_error(error, status)
    @room = @user = nil
    @error = { key: t("error.room.#{error}.code"), message: t("error.room.#{error}.message"), suggestion: t("error.room.#{error}.suggestion"), status: status }
  end

  def authenticate_user!
    @launch_nonce = params['launch_nonce']
    return unless omniauth_provider?(:bbbltibroker)
    # Assume user authenticated if session [params[launch_nonce]] is set
    return if session[@launch_nonce]

    redirect_to(omniauth_authorize_path(:bbbltibroker, launch_nonce: params[:launch_nonce])) && return if params['action'] == 'launch'

    redirect_to(errors_path(401))
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_room
    @room = Room.find_by(id: params[:id])
    # Exit with error if room was not found
    set_error('notfound', :not_found) && return unless @room
    # Exit with error by re-setting the room to nil if the session for the room.handler is not set
    set_error('forbidden', :forbidden) && return unless session[@room.handler]

    # Continue through happy path
    @user = BbbAppRooms::User.new(session[@room.handler][:user_params])
  end

  def set_launch
    # Pull the Launch request_parameters.
    bbbltibroker_url = omniauth_bbbltibroker_url("/api/v1/sessions/#{@launch_nonce}")
    session_params = JSON.parse(RestClient.get(bbbltibroker_url, 'Authorization' => "Bearer #{omniauth_client_token(omniauth_bbbltibroker_url)}"))
    # Exit with error if session_params is not valid.
    set_error('forbidden', :forbidden) && return unless session_params['valid']

    launch_params = session_params['message']

    # Exit with error if user is not authenticated.
    set_error('forbidden', :forbidden) && return unless launch_params['user_id'] == session[@launch_nonce]['uid']

    # Continue through happy path.
    @room = Room.find_or_create_by(handler: resource_handler(launch_params)) do |room|
      room.update(launch_params_to_new_room_params(launch_params))
    end
    user_params = launch_params_to_new_user_params(launch_params)
    session[@room.handler] = { user_params: user_params }
  end

  def room_params
    params.require(:room).permit(:name, :description, :welcome, :moderator, :viewer, :recording, :wait_moderator, :all_moderators)
  end

  def new_room_params(handler, name, description, recording = false, wait_moderator = false, all_moderators = false)
    params.permit.merge(
      handler: handler,
      name: name,
      description: description,
      welcome: '',
      recording: recording,
      wait_moderator: wait_moderator,
      all_moderators: all_moderators
    )
  end

  def launch_params_to_new_room_params(launch_params)
    handler = resource_handler(launch_params)
    name = launch_params['resource_link_title']
    description = launch_params['resource_link_description']
    record = message_has_custom?(launch_params, 'record')
    wait_moderator = message_has_custom?(launch_params, 'wait_moderator')
    all_moderators = message_has_custom?(launch_params, 'all_moderators')
    new_room_params(handler, name, description, record, wait_moderator, all_moderators)
  end

  def launch_params_to_new_user_params(launch_params)
    {
      uid: launch_params['user_id'],
      full_name: launch_params['lis_person_name_full'],
      first_name: launch_params['lis_person_name_given'],
      last_name: launch_params['lis_person_name_family'],
      email: launch_params['lis_person_contact_email_primary'],
      roles: launch_params['roles'],
    }
  end

  def message_has_custom?(message, type)
    message.key?('custom_params') && message['custom_params'].key?('custom_' + type) && message['custom_params']['custom_' + type] == 'true'
  end

  def check_for_cancel
    redirect_to(room_path(@room, launch_nonce: params[:launch_nonce])) if params[:cancel]
  end

  def resource_handler(params)
    Digest::SHA1.hexdigest('rooms' + params['tool_consumer_instance_guid'] + params['resource_link_id']).to_s
  end

  def allow_iframe_requests
    response.headers.delete('X-Frame-Options')
  end
end
