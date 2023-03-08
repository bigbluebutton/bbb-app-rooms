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

require 'json'
require 'uri'
require 'bbb_app_rooms/user'
require 'net/http'

class RoomsController < ApplicationController
  # Include libraries.
  include BbbAppRooms
  # Include concerns.
  include BbbHelper
  include OmniauthHelper

  before_action :print_parameters if Rails.configuration.developer_mode_enabled
  before_action :authenticate_user!, except: %i[meeting_close], raise: false
  before_action :set_launch, only: %i[launch]
  before_action :set_room, except: %i[launch]
  before_action :check_for_cancel, only: [:create, :update]
  before_action :allow_iframe_requests
  before_action :set_current_locale
  after_action :broadcast_meeting, only: [:meeting_end]

  # GET /rooms/1
  # GET /rooms/1.json
  def show
    respond_to do |format|
      if @room
        begin
          @recordings = recordings
        rescue BigBlueButton::BigBlueButtonException => e
          logger.error(e.to_s)
          flash.now[:alert] = t('default.recording.server_down')
          @recordings = []
        end

        format.html { render(:show) }
        format.json { render(:show, status: :ok, location: @room) }
      else
        format.html { render(:error, status: @error[:status]) }
        format.json { render(json: { error: @error[:message] }, status: @error[:status]) }
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
        format.html { redirect_to(@room, notice: t('default.room.created')) }
        format.json { render(:show, status: :created, location: @room) }
      else
        format.html { render(:new) }
        format.json { render(json: @error, status: :unprocessable_entity) }
      end
    end
  end

  # PATCH/PUT /rooms/1
  # PATCH/PUT /rooms/1.json
  def update
    respond_to do |format|
      if @room.update(room_params)
        format.html { redirect_to(room_path(@room, launch_nonce: params[:launch_nonce]), notice: t('default.room.updated')) }
        format.json { render(:show, status: :ok, location: @room) }
      else
        format.html { render(:edit) }
        format.json { render(json: @error, status: :unprocessable_entity) }
      end
    end
  end

  # DELETE /rooms/1
  # DELETE /rooms/1.json
  def destroy
    @room.destroy
    respond_to do |format|
      format.html { redirect_to(rooms_url, notice: t('default.room.destroyed')) }
      format.json { head(:no_content) }
    end
  end

  # GET /launch
  # GET /launch.json?
  def launch
    redirect_to(room_path(@room.id, launch_nonce: params['launch_nonce'])) && return if @room

    redirect_to(errors_path(410))
  end

  # POST /rooms/:id/meeting/join
  # POST /rooms/:id/meeting/join.json
  def meeting_join
    wait = wait_for_mod? && !meeting_running?
    @meeting = join_meeting_url

    if wait
      respond_to do |format|
        format.html
        format.json { render(json: { wait_for_mod: wait, meeting: @meeting }) }
      end
    else
      broadcast_meeting(action: 'join', delay: true)
      NotifyRoomWatcherJob.set(wait: 5.seconds).perform_later(@room, { action: 'started' }) if @room.wait_moderator
      redirect_to(@meeting)
    end
  end

  # GET /rooms/:id/meeting/end
  # GET /rooms/:id/meeting/end.json
  def meeting_end
    end_meeting
    redirect_to(room_path(@room.id, launch_nonce: params['launch_nonce'])) # fallback if actioncable doesn't work
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
      format.html { render(:autoclose) }
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
    case params[:setting]
    when 'rename_recording'
      update_recording(params[:record_id], 'meta_name' => params[:record_name])
    when 'describe_recording'
      update_recording(params[:record_id], 'meta_description' => params[:record_description])
    end
  end

  # POST /rooms/:id/recording/:record_id/delete
  def recording_delete
    delete_recording(params[:record_id])
    redirect_to(room_path(params[:id], launch_nonce: params[:launch_nonce]))
  end

  # POST /rooms/:id/recording/:record_id/:format/recording
  # Makes an API call to the BBB server to retrieve an individual recording
  # Used in the case of protected recordings because they can't be cached.
  def individual_recording
    rec = recording(params[:record_id])
    formats_arr = rec[:playback][:format]
    format_obj = formats_arr.find { |i| i[:type] == params[:format] }

    playback_url = format_obj[:url]

    redirect_to(playback_url) && return unless playback_url.nil?

    redirect_to(errors_path(401))
  end

  helper_method :recording_date, :recording_length, :meeting_running?, :bigbluebutton_moderator_roles,
                :bigbluebutton_recording_public_formats, :meeting_info, :bigbluebutton_recording_enabled, :server_running?

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

    redirector = omniauth_authorize_path(:bbbltibroker, launch_nonce: params[:launch_nonce])
    redirect_post(redirector, options: { authenticity_token: :auto }) && return if params['action'] == 'launch'

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
    logger.debug(session_params.to_yaml) if Rails.configuration.developer_mode_enabled

    # Exit with error if session_params is not valid.
    set_error('forbidden', :forbidden) && return unless session_params['valid']

    launch_params = session_params['message']

    # Exit with error if user is not authenticated.
    set_error('forbidden', :forbidden) && return unless launch_params['user_id'] == session[@launch_nonce]['uid']

    # Continue through happy path.
    launch_room(launch_params, session_params['tenant'].presence)
    launch_user(launch_params) if @room
  end

  def launch_room(launch_params, tenant)
    handler = Digest::SHA1.hexdigest("rooms#{tenant}#{launch_params['resource_link_id']}")
    handler_legacy = launch_params['custom_params']['custom_handler_legacy'].presence
    @room = Room.find_by(handler: handler, handler_legacy: handler_legacy, tenant: tenant)

    # Exit if this is a launch on an existing room or continue path for new rooms.
    return if @room

    # For a legacy launch.
    unless handler_legacy.nil?
      # Fetch room parameters if the API is enabled.
      fetched_room_params = fetch_new_room_params(handler, handler_legacy) if Rails.configuration.handler_legacy_api_enabled
      # Create new room with fetched params if fetched.
      @room = Room.create(fetched_room_params.merge({ tenant: tenant })) if fetched_room_params
      # Exit if the room was created.
      return if @room
      # When new room creation is disabled, there is nothing else to do, just exit.
      return unless Rails.configuration.handler_legacy_new_room_enabled
    end

    # For any regular launch or if the new room creation for legacy launches is enabled.
    launch_room_params = launch_params_to_new_room_params(handler, handler_legacy, launch_params)
    @room = Room.create(launch_room_params.merge({ tenant: tenant }))
  end

  def launch_user(launch_params)
    user_params = launch_params_to_new_user_params(launch_params)
    session[@room.handler] = { user_params: user_params }
  end

  def room_params
    params.require(:room).permit(
      :name,
      :description,
      :welcome,
      :moderator,
      :viewer,
      :recording,
      :wait_moderator,
      :all_moderators,
      :hide_name,
      :hide_description,
      settings: Room.stored_attributes[:settings]
    )
  end

  def launch_params_to_new_room_params(handler, handler_legacy, launch_params)
    params.permit.merge(
      handler: handler,
      handler_legacy: handler_legacy,
      name: launch_params['resource_link_title'] || t('default.room.room'),
      description: launch_params['resource_link_description'] || '',
      welcome: '',
      recording: launch_params['custom_params'].key?('custom_record') ? launch_params['custom_params']['custom_record'] : true,
      wait_moderator: message_has_custom?(launch_params, 'wait_moderator') || false,
      all_moderators: message_has_custom?(launch_params, 'all_moderators') || false,
      hide_name: message_has_custom?(launch_params, 'hide_name') || false,
      hide_description: message_has_custom?(launch_params, 'hide_description') || false,
      settings: message_has_custom?(launch_params, 'settings') || {}
    )
  end

  def fetch_new_room_params(handler, handler_legacy)
    handler_legacy_api_url = "#{Rails.configuration.handler_legacy_api_endpoint}rooms/#{handler_legacy}"
    checksum = Digest::SHA256.hexdigest(handler_legacy_api_url + Rails.configuration.handler_legacy_api_secret)
    logger.debug("Fetching from: #{handler_legacy_api_url}?checksum=#{checksum}")
    uri = URI("#{handler_legacy_api_url}?checksum=#{checksum}")
    res = Net::HTTP.get_response(uri)
    return nil unless res.is_a?(Net::HTTPSuccess)

    room = JSON.parse(res.body)
    params.permit.merge(
      handler: handler,
      handler_legacy: handler_legacy,
      name: room['name'],
      description: room['description'],
      welcome: room['welcome'],
      moderator: room['moderator'],
      viewer: room['viewer'],
      recording: room['recording'],
      wait_moderator: room['wait_moderator'],
      all_moderators: room['all_moderators'],
      settings: {
        waitForModerator: room['wait_moderator'],
        record: room['recording'],
        allModerators: room['all_moderators'],
      }
    )
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
    message.key?('custom_params') && message['custom_params'].key?("custom_#{type}") && message['custom_params']["custom_#{type}"] == 'true'
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
