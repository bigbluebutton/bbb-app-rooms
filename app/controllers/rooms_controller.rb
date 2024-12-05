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
  before_action :set_action_cable, only: %i[launch]
  before_action :set_ext_params, except: [:launch]

  after_action :broadcast_meeting, only: [:meeting_end]

  # GET /rooms/1
  # GET /rooms/1.json
  def show
    # page offset is equal to the page number minus 1
    @page = params[:page] || 1
    session[:page] = @page
    respond_to do |format|
      if @room && @chosen_room
        begin
          @recordings = recordings(@page)
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
      if @room.update(room_params)
        format.html { redirect_to(room_path(@room, launch_nonce: params[:launch_nonce]), notice: t('default.room.updated')) }
        format.json { render(:show, status: :ok, location: @room) }
      else
        # If the room wasn't updated because a code was not found then show an error message
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

    @meeting = join_meeting_url

    broadcast_meeting(action: 'join')
    redirect_to(@meeting)
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

  def broadcast_meeting(action: 'none')
    RoomMeetingWatcherJob.set(wait: 5.seconds).perform_later(@chosen_room, action: action) unless @chosen_room.watcher_job_active
  end

  # GET /rooms/:id/meeting/close
  def meeting_close
    respond_to do |format|
      broadcast_meeting(action: 'someone left')
      format.html { render(:autoclose) }
    end
  end

  # POST /rooms/:id/recording/:record_id/unpublish
  def recording_unpublish
    unpublish_recording(params[:record_id])
    @page_num = session[:page] || 1
    redirect_to(room_path(params[:id], launch_nonce: params[:launch_nonce], page: @page_num))
  end

  # POST /rooms/:id/recording/:record_id/publish
  def recording_publish
    publish_recording(params[:record_id])
    @page_num = session[:page] || 1
    redirect_to(room_path(params[:id], launch_nonce: params[:launch_nonce], page: @page_num))
  end

  # POST /rooms/:id/recording/:record_id/protect
  def recording_protect
    update_recording(params[:record_id], protect: true)
    @page_num = session[:page] || 1
    redirect_to(room_path(params[:id], launch_nonce: params[:launch_nonce], page: @page_num))
  end

  # POST /rooms/:id/recording/:record_id/unprotect
  def recording_unprotect
    update_recording(params[:record_id], protect: false)
    @page_num = session[:page] || 1
    redirect_to(room_path(params[:id], launch_nonce: params[:launch_nonce], page: @page_num))
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
    @page_num = session[:page] || 1
    redirect_to(room_path(params[:id], launch_nonce: params[:launch_nonce], page: @page_num))
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

  helper_method :recording_date, :recording_length, :meeting_running?, :bigbluebutton_moderator_roles, :paginate?, :recordings_count, :pages_count,
                :bigbluebutton_recording_public_formats, :meeting_info, :bigbluebutton_recording_enabled, :server_running?

  private

  def set_error(error, status, domain = 'room')
    @room = @user = nil
    @error = {
      key: t("error.#{domain}.#{error}.code", default: t("error.#{domain}.default.code")),
      message: t("error.#{domain}.#{error}.message", default: t("error.#{domain}.default.message")),
      suggestion: t("error.#{domain}.#{error}.suggestion", default: t("error.#{domain}.default.suggestion")),
      status: status,
    }
  end

  def authenticate_user!
    @launch_nonce = params['launch_nonce']
    return unless omniauth_provider?(:bbbltibroker)

    # Assume user authenticated if session [params[launch_nonce]] is set
    return if session[@launch_nonce]

    redirector = omniauth_authorize_url(:bbbltibroker, launch_nonce: @launch_nonce)
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
    # See whether shared rooms have been enabled in tenant settings. They are disabled by default.
    @shared_rooms_enabled = tenant_setting(@room&.tenant, 'enable_shared_rooms') == 'true'

    if @shared_rooms_enabled && @room&.use_shared_code
      @shared_room = Room.find_by(code: @room.shared_code, tenant: @room.tenant)
      use_shared_room = @shared_room.present?
      logger.debug("Room with id #{params[:id]} is using shared code: #{@room&.shared_code}")
    else
      @shared_room = nil
      use_shared_room = false
    end

    @chosen_room = use_shared_room ? @shared_room : @room
  end

  def launch_request_params
    # Pull the Launch request_parameters.
    logger.debug('Pulling the Launch request_parameters...')
    bbbltibroker_url = omniauth_bbbltibroker_url("/api/v1/sessions/#{@launch_nonce}")
    get_response = RestClient.get(bbbltibroker_url, 'Authorization' => "Bearer #{omniauth_client_token(omniauth_bbbltibroker_url)}")
    session_params = JSON.parse(get_response)
    logger.debug(session_params['message'].to_h.sort.to_h.to_yaml) if Rails.configuration.developer_mode_enabled

    # Exit with error if session_params is not valid.
    set_error('forbidden', :forbidden) && return unless session_params['valid']

    session_params
  end

  def set_launch
    request_params = launch_request_params
    launch_params = request_params['message']

    # Exit with error if user is not authenticated.
    set_error('forbidden', :forbidden) && return unless launch_params['user_id'] == session[@launch_nonce]['uid']

    # Continue through happy path.
    launch_room(launch_params, request_params['tenant'].presence)
    launch_user(launch_params) if @room
  end

  def launch_room(launch_params, tenant)
    handler = room_handler(launch_params, tenant)
    handler_legacy = launch_params['custom_params']['custom_handler_legacy'].presence
    code = SecureRandom.alphanumeric(10)

    ## Any launch.
    @room = Room.find_by(handler: handler, tenant: tenant)
    logger.debug("Room #{@room.id} found...") && return if @room

    launch_room_params = launch_params_to_new_room_params(handler, handler_legacy, launch_params).merge({ tenant: tenant })
    if handler_legacy.nil?
      ## Regular launch
      logger.debug('This is a Regular launch...')
      @room = Room.create(launch_room_params.merge({ code: code, shared_code: code }))
      logger.debug(@room.errors.full_messages) if @room.errors.any?
      return
    end

    # Legacy launch.
    logger.debug('This is a Legacy launch...')
    if Rails.configuration.handler_legacy_api_enabled
      # Attempt creating a Legacy Room with fetched parameters
      logger.debug('Attempting to create a Legacy Room with fetched parameters...')
      fetched_room_params = fetch_new_room_params(handler, handler_legacy)
      unless fetched_room_params.nil?
        fetched_room_params = fetched_room_params.merge({ tenant: tenant })
        @room = Room.find_by(handler: fetched_room_params['handler'], tenant: tenant)
        if @room
          # Update
          @room = Room.update(fetched_room_params)
          logger.debug("Room #{@room.id} updated with fetched parameters...") && return if @room
        else
          # Create
          @room = Room.create(fetched_room_params.merge({ code: code, shared_code: code }))
          if @room.persisted?
            logger.debug("Room #{@room.id} created with fetched parameters...") && return if @room
          else
            logger.debug("Room creation failed: #{@room.errors.full_messages.join(', ')}")
          end
        end
        logger.debug(@room.errors.full_messages) if @room.errors.any?
      end
    end

    # Attempt creating a Legacy Room with launch parameters only if the new room creation for legacy launches is enabled.
    return unless Rails.configuration.handler_legacy_new_room_enabled

    logger.debug('It will attempt to create a Room with passed parameters even though a handler_legacy was passed...')
    @room = Room.create(launch_room_params.merge({ code: code, shared_code: code }))
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
      all_moderators: room['all_moderators'],
      settings: {
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
      user_image: launch_params['user_image'] || launch_params['custom_user_image'],
      lis_person_pronouns: launch_params['lis_person_pronouns'] || launch_params['custom_lis_person_pronouns'],
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
    room_handler_params = tenant_setting(tenant, 'handler_params')&.split(',').presence || ['resource_link_id']

    room_handler_params.each do |param|
      param_val = launch_params[param]
      input += param_val.to_s if param_val
    end

    Digest::SHA1.hexdigest(input)
  end

  def set_action_cable
    relative_url_root = Rails.configuration.relative_url_root
    relative_url_root = relative_url_root.chop if relative_url_root[-1] == '/'
    config = ActionCable::Server::Configuration.new
    config.cable = { url: "wss://#{request.host}#{relative_url_root}/rooms/cable" }

    ActionCable::Server::Base.new(config: config)
  end

  def set_ext_params
    logger.debug('[Rooms Controller] Setting ext_params in room controller.')
    tenant = @chosen_room.tenant
    @broker_ext_params ||= tenant_setting(tenant, 'ext_params')

    launch_params = if Rails.configuration.cache_enabled
                      Rails.cache.fetch("rooms/#{@chosen_room.handler}/tenant/#{tenant}/user/#{@user.uid}/launch_params",
                                        expires_in: Rails.configuration.cache_expires_in_minutes.minutes) do
                        logger.debug('fetching launch params for extra params from cache')
                        launch_request_params['message']
                      end
                    else
                      launch_request_params['message']
                    end

    logger.debug("[Rooms Controller] extra params from broker for room #{@chosen_room.name}: #{@broker_ext_params}")

    pass_on_join_params = launch_and_extra_params_intersection_hash(launch_params, 'join', @broker_ext_params&.[]('join'))
    pass_on_create_params = launch_and_extra_params_intersection_hash(launch_params, 'create', @broker_ext_params&.[]('create'))

    @extra_params_to_bbb = { 'join' => pass_on_join_params, 'create' => pass_on_create_params }

    logger.debug("[Rooms Controller] The extra parameters to be passed to BBB are: #{@extra_params_to_bbb}")
  rescue StandardError => e
    logger.error("[Rooms Controller] Error setting extra parameters: #{e}")
  end

  # return a hash of key:value pairs from the launch_params,
  # for keys that exist in the extra params hash retrieved from the broker settings
  def launch_and_extra_params_intersection_hash(launch_params, action, actions_hash)
    if Rails.configuration.cache_enabled
      Rails.cache.fetch("rooms/#{@chosen_room.handler}/tenant/#{@chosen_room.tenant}/user/#{@user.uid}/ext_#{action}_params",
                        expires_in: Rails.configuration.cache_expires_in_minutes.minutes) do
        calculate_intersection_hash(launch_params, actions_hash)
      end
    else
      calculate_intersection_hash(launch_params, actions_hash)
    end
  end

  def calculate_intersection_hash(launch_params, actions_hash)
    result = {}
    actions_hash&.each_key do |key|
      value = find_launch_param(launch_params, key)
      result[key] = value if value
    end
    result
  end

  # Check if the launch params contain a certain param
  # If they do, return the value of that param
  def find_launch_param(launch_params, key)
    return launch_params[key] if launch_params.key?(key)

    launch_params.each_value do |value|
      if value.is_a?(Hash)
        result = find_launch_param(value, key)
        return result unless result.nil?
      end
    end

    nil
  end
end
