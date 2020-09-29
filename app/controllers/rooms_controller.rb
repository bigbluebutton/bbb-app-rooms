# frozen_string_literal: true

#  BigBlueButton open source conferencing system - http://www.bigbluebutton.org/.
#
#  Copyright (c) 2018 BigBlueButton Inc. and by respective authors (see below).
#
#  This program is free software; you can redistribute it and/or modify it under the
#  terms of the GNU Lesser General Public License as published by the Free Software
#  Foundation; either version 3.0 of the License, or (at your option) any later
#  version.
#
#  BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
#  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
#  PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public License along
#  with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.

require 'bbb_app_rooms/user'

class RoomsController < ApplicationController
  # Include libraries.
  include BbbAppRooms
  # Include concerns.
  include BbbHelper
  include OmniauthHelper

  before_action :authenticate_user!, except: %i[meeting_close], raise: false
  before_action :set_launch, only: %i[launch]
  before_action :set_room, except: %i[launch]
  before_action :check_for_cancel, only: [:create, :update]
  before_action :allow_iframe_requests
  before_action :set_current_locale
  after_action :broadcast_meeting, only: [:show, :launch, :meeting_end]

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
    wait = wait_for_mod? && !meeting_running?
    broadcast_meeting(action: 'join', delay: true) unless wait
    NotifyRoomWatcherJob.set(wait: 5.seconds).perform_later(@room) unless wait
    render(json: { wait_for_mod: wait, meeting: join_meeting_url }, status: :ok)
  end

  # GET /rooms/:id/meeting/end
  # GET /rooms/:id/meeting/end.json
  def meeting_end
    end_meeting
  end

  def broadcast_meeting(action: 'none', delay: false)
    if delay
      NotifyMeetingWatcherJob.set(wait: 5.seconds).perform_later(@room, action: action)
    else
      NotifyMeetingWatcherJob.perform_now(@room, action: action)
    end
  end

  # GET /rooms/:id/meeting/close
  def meeting_close
    respond_to do |format|
      broadcast_meeting(action: 'someone left', delay: true)
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

  # POST /rooms/:id/recording/:record_id/protect
  def recording_protect
    update_recording(params[:record_id], protect: true)
    redirect_to(room_path(params[:id], launch_nonce: params[:launch_nonce]))
  end

  # POST /rooms/:id/recording/:record_id/unprotect
  def recording_unprotect
    update_recording(params[:record_id], protect: false)
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

  helper_method :recordings, :recording_date, :recording_length, :meeting_running?, :bigbluebutton_moderator_roles, :bigbluebutton_recording_public_formats, :meeting_info

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
    get_response = RestClient.get(bbbltibroker_url, 'Authorization' => "Bearer #{omniauth_client_token(omniauth_bbbltibroker_url)}")
    session_params = JSON.parse(get_response)
    # Exit with error if session_params is not valid.
    set_error('forbidden', :forbidden) && return unless session_params['valid']

    launch_params = session_params['message']

    # Exit with error if user is not authenticated.
    set_error('forbidden', :forbidden) && return unless launch_params['user_id'] == session[@launch_nonce]['uid']

    # Continue through happy path.
    @tenant = session_params['tenant']
    resource_handler = Digest::SHA1.hexdigest('rooms' + @tenant + launch_params['tool_consumer_instance_guid'] + launch_params['resource_link_id'])
    @room = Room.find_or_create_by(handler: resource_handler, tenant: @tenant) do |room|
      room.update(launch_params_to_new_room_params(launch_params))
    end
    user_params = launch_params_to_new_user_params(launch_params)
    session[@room.handler] = { user_params: user_params }
  end

  def room_params
    params.require(:room).permit(:name, :description, :welcome, :moderator, :viewer, :recording, :wait_moderator, :all_moderators)
  end

  def new_room_params(name, description, recording = true, wait_moderator = false, all_moderators = false)
    params.permit.merge(
      name: name,
      description: description,
      welcome: '',
      recording: recording,
      wait_moderator: wait_moderator,
      all_moderators: all_moderators
    )
  end

  def launch_params_to_new_room_params(launch_params)
    name = launch_params['resource_link_title']
    description = launch_params['resource_link_description']
    record = launch_params['custom_params'].key?('custom_' + 'record') ? launch_params['custom_params']['custom_' + 'record'] : true
    wait_moderator = message_has_custom?(launch_params, 'wait_moderator')
    all_moderators = message_has_custom?(launch_params, 'all_moderators')
    new_room_params(name, description, record, wait_moderator, all_moderators)
  end

  def launch_params_to_new_user_params(launch_params)
    {
      uid: launch_params['user_id'],
      full_name: launch_params['lis_person_name_full'],
      first_name: launch_params['lis_person_name_given'],
      last_name: launch_params['lis_person_name_family'],
      email: launch_params['lis_person_contact_email_primary'],
      roles: launch_params['roles'],
      locale: launch_params['launch_presentation_locale'],
    }
  end

  def message_has_custom?(message, type)
    message.key?('custom_params') && message['custom_params'].key?('custom_' + type) && message['custom_params']['custom_' + type] == 'true'
  end

  def check_for_cancel
    redirect_to(room_path(@room, launch_nonce: params[:launch_nonce])) if params[:cancel]
  end

  def allow_iframe_requests
    response.headers.delete('X-Frame-Options')
  end

  def set_current_locale
    locale = nil

    # try to get the locale from the LTI launch, otherwise use the browser's
    if @user.present? && @user.locale.present?
      locale = @user.locale
    elsif !request.env['HTTP_ACCEPT_LANGUAGE'].nil?
      locale = request.env['HTTP_ACCEPT_LANGUAGE'].first
    end

    I18n.available_locales.each do |av_loc|
      if /^#{av_loc}/i.match?(locale)
        I18n.locale = av_loc
        break
      end
    end

    response.set_header('Content-Language', I18n.locale)
  end
end
