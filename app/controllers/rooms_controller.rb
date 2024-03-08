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
require 'rooms_error/error'

class RoomsController < ApplicationController
  # Include libraries.
  include BbbAppRooms
  include RoomsError
  # Include concerns.
  include BbbHelper
  include OmniauthHelper
  include BrokerHelper

  before_action :print_parameters if Rails.configuration.developer_mode_enabled
  before_action :authenticate_user!, except: %i[meeting_close], raise: false
  before_action :set_launch, only: %i[launch]
  before_action :set_room, except: %i[launch]
  before_action :set_chosen_room, except: %i[launch]
  before_action :check_for_cancel, only: [:create, :update]
  before_action :allow_iframe_requests
  before_action :set_current_locale
  after_action :broadcast_meeting, only: [:meeting_end]

  # GET /rooms/1
  # GET /rooms/1.json
  def show
    respond_to do |format|
      if @room && @chosen_room
        begin
          @recordings = recordings
          @meeting_info = meeting_info
          @meeting_running = @meeting_info[:returncode] == true
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

  # if there's an error besides the server being down (ex. something wrong with initializing the BBB API)
  rescue RoomsError::CustomError => e
    @error = e.fetch_json
    respond_to do |format|
      format.html { render(:error, status: @error[:status]) }
      format.json { render(json: { error: @error[:message] }, status: @error[:status]) }
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
      # block update if shared_code doesn't exist
      shared_code = room_params[:shared_code]
      code_found =  shared_code.blank? ? true : Room.where(code: shared_code, tenant: @room.tenant).exists?

      if code_found && @room.update(room_params)
        format.html { redirect_to(room_path(@room, launch_nonce: params[:launch_nonce]), notice: t('default.room.updated')) }
        format.json { render(:show, status: :ok, location: @room) }
      else
        # If the room wasn't updated because a code was not found then show an error message
        flash.now[:alert] = code_found ? nil : t('error.room.codenotfound.message')
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
    @user.full_name ||= cookies[:full_name] # if full_name in cookies, use that.
    @user.full_name ||= params[:full_name] # if it's coming form name_form, this param will be populated
    cookies[:full_name] ||= @user.full_name # set cookie if null

    # if name was not passed by the LMS, prompt for name before joining meeting
    unless @user.full_name
      respond_to do |format|
        format.html { render(:name_form) }
      end and return
    end

    wait = wait_for_mod? && !meeting_running?
    @meeting = join_meeting_url

    if wait
      respond_to do |format|
        format.html
        format.json { render(json: { wait_for_mod: wait, meeting: @meeting }) }
      end
    else
      broadcast_meeting(action: 'join', delay: true)
      NotifyRoomWatcherJob.perform_now(@chosen_room, { action: 'started' })
      redirect_to(@meeting)
    end
  rescue BigBlueButton::BigBlueButtonException => e
    logger.error(e.to_s)
    set_error(e.key, 500, 'bigbluebutton')
    respond_to do |format|
      format.html { render(:error, status: @error[:status]) }
      format.json { render(json: { error: @error[:message] }, status: @error[:status]) }
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
      NotifyMeetingWatcherJob.set(wait: 5.seconds).perform_later(@chosen_room, action: action)
    else
      NotifyMeetingWatcherJob.perform_now(@chosen_room, action: action)
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
                :bigbluebutton_recording_public_formats, :meeting_info, :bigbluebutton_recording_enabled, :server_running?, :shared_rooms_enabled, :hide_build_tag

  private

  def set_error(error, status, domain = 'room')
    @room = @user = nil
    @error = { key: t("error.#{domain}.#{error}.code"), message: t("error.#{domain}.#{error}.message"), suggestion: t("error.#{domain}.#{error}.suggestion"), status: status }
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

  # If the room is using a shared code, then use the shared room's recordings and bbb link
  def set_chosen_room
    @shared_rooms_enabled = shared_rooms_enabled(@room&.tenant)
    @shared_room = Room.find_by(code: @room.shared_code, tenant: @room.tenant) if @shared_rooms_enabled && @room&.use_shared_code

    use_shared_room = @shared_rooms_enabled && @room&.use_shared_code && Room.where(code: @room.shared_code, tenant: @room.tenant).exists?

    logger.debug("Room with id #{params[:id]} is using shared code: #{@room&.shared_code}") if @shared_rooms_enabled && @room&.use_shared_code

    @chosen_room = use_shared_room ? @shared_room : @room
  end

  def set_launch
    # Pull the Launch request_parameters.
    bbbltibroker_url = omniauth_bbbltibroker_url("/api/v1/sessions/#{@launch_nonce}")
    get_response = RestClient.get(bbbltibroker_url, 'Authorization' => "Bearer #{omniauth_client_token(omniauth_bbbltibroker_url)}")
    session_params = JSON.parse(get_response)
    logger.debug(session_params['message'].to_h.sort.to_h.to_yaml) if Rails.configuration.developer_mode_enabled

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
    handler = room_handler(launch_params, tenant)
    handler_legacy = launch_params['custom_params']['custom_handler_legacy'].presence

    ## Any launch.
    @room = Room.find_by(handler: handler, tenant: tenant)
    return if @room

    # Legacy launch.
    unless handler_legacy.nil?
      # Attempt creating a Legacy Room with fetched parameters
      fetched_room_params = fetch_new_room_params(handler, handler_legacy) if Rails.configuration.handler_legacy_api_enabled
      @room = Room.create(fetched_room_params.merge({ tenant: tenant })) if fetched_room_params
      return if @room

      # Attempt creating a Legacy Room with launch parameters only if the new room creation for legacy launches is enabled.
      return unless Rails.configuration.handler_legacy_new_room_enabled
    end

    ## Regular launch
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
      :code,
      :shared_code,
      :use_shared_code,
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
      settings: message_has_custom?(launch_params, 'settings') || {},
      code: '',
      shared_code: '',
      use_shared_code: false
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

  # Generate room handler based on the settings pulled from the broker
  def room_handler(launch_params, tenant)
    input = "rooms#{tenant}"

    # use resource_link_id as the default param if nothing was specified in the broker settings
    room_handler_params = handler_params(tenant).presence || ['resource_link_id']

    room_handler_params.each do |param|
      param_val = launch_params[param]
      input += param_val.to_s if param_val
    end

    Digest::SHA1.hexdigest(input)
  end
end
