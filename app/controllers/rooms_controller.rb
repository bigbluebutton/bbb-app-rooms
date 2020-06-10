class RoomsController < ApplicationController
  include ApplicationHelper
  include BigBlueButtonHelper
  before_action :authenticate_user!, :raise => false
  before_action :set_launch_room, only: %i[launch]
  before_action :set_room, only: %i[show edit update destroy meeting_join meeting_end meeting_close]
  before_action :check_for_cancel, :only => [:create, :update]

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
        format.html { render :show }
        format.json { render :show, status: :ok, location: @room }
      else
        format.html { render :error, status: @error[:status] }
        format.json { render json: {error:  @error[:message]}, status: @error[:status] }
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
    redirector = room_path(@room.id)
    redirect_to redirector
  end

  # POST /rooms/:id/meeting/join
  # POST /rooms/:id/meeting/join.json
  def meeting_join
    # make user wait until moderator is in room
    if wait_for_mod? && ! mod_in_room?
      render json: { :wait_for_mod => true } , status: :ok
    else
      NotifyRoomWatcherJob.set(wait: 5.seconds).perform_later(@room)
      redirect_to join_meeting_url
    end
  end

  # GET /rooms/:id/meeting/end
  # GET /rooms/:id/meeting/end.json
  def meeting_end
  end

  # GET /rooms/:id/meeting/close
  def meeting_close
    respond_to do |format|
      format.html { render :autoclose }
    end
  end

  # POST /rooms/:id/recording/:record_id/unpublish
  def recording_unpublish
    unpublish_recording(params[:record_id])
    redirect_to room_path(params[:id])
  end

  # POST /rooms/:id/recording/:record_id/publish
  def recording_publish
    publish_recording(params[:record_id])
    redirect_to room_path(params[:id])
  end

  # POST /rooms/:id/recording/:record_id/update
  def recording_update
    if params[:setting] == "rename_recording"
      update_recording(params[:record_id], "meta_name" => params[:record_name])
    elsif params[:setting] == "describe_recording"
      update_recording(params[:record_id], "meta_description" => params[:record_description])
    end
    redirect_to room_path(params[:id])
  end

  # POST /rooms/:id/recording/:record_id/delete
  def recording_delete
    delete_recording(params[:record_id])
    redirect_to room_path(params[:id])
  end

  private

    def set_error(error, status)
      @room = @user = nil
      @error = { key: t("error.room.#{error}.code"), message:  t("error.room.#{error}.message"), suggestion: t("error.room.#{error}.suggestion"), :status => status }
    end

    def authenticate_user!
      return unless omniauth_provider?(:bbbltibroker)
      # Assume user authenticated if session[:omaniauth_auth] is set
      return if session['omniauth_auth'] && Time.now.to_time.to_i < session['omniauth_auth']["credentials"]["expires_at"].to_i
      session[:callback] = request.original_url
      if params['action'] == 'launch'
        redirector = omniauth_authorize_path(:bbbltibroker, launch_nonce: params[:launch_nonce])
        redirect_to redirector and return
      end
      redirect_to errors_path(401)
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_room
      @room = Room.find_by(id: params[:id])
      # Exit with error if room was not found
      set_error('notfound', :not_found) and return unless @room
      # Exit with error by re-setting the room to nil if the session for the room.handler is not set
      set_error('forbidden', :forbidden) and return unless session[@room.handler] && session[@room.handler]['expires'].to_time > Time.now.to_time
      # Continue through happy path
      @user = User.find_by(uid: session['omniauth_auth']['uid'])
    end

    def set_launch_room
      launch_nonce = params['launch_nonce'] #|| session['omniauth_params']['launch_nonce']
      # Pull the Launch request_parameters
      bbbltibroker_url = omniauth_bbbltibroker_url("/api/v1/sessions/#{launch_nonce}")
      session_params = JSON.parse(RestClient.get(bbbltibroker_url, {'Authorization' => "Bearer #{omniauth_client_token(omniauth_bbbltibroker_url)}"}))
      # Exit with error if session_params is not valid
      set_error('forbidden', :forbidden) and return unless session_params['valid']
      # Continue through happy path
      launch_params = session_params['message']

      @room = Room.find_or_create_by(handler: resource_handler(launch_params)) do |room|
        room.update(launch_params_to_new_room_params(launch_params))
      end
      @user = User.find_or_create_by(uid: launch_params['user_id']) do |user|
        user.update(launch_params_to_new_user_params(launch_params))
      end
      session[@room.handler] = {expires: 30.minutes.from_now }
    end

    def room_params
      params.require(:room).permit(:name, :description, :welcome, :moderator, :viewer, :recording, :wait_moderator, :all_moderators)
    end

    def launch_params_to_new_user_params(launch_params)
      {
        uid: launch_params['user_id'],
        roles: launch_params['roles'],
        full_name: launch_params['lis_person_name_full'],
        first_name: launch_params['lis_person_name_given'],
        last_name: launch_params['lis_person_name_family'],
        email: launch_params['lis_person_contact_email_primary'],
      }
    end

    def new_room_params(handler, name, description, recording=false, wait_moderator=false, all_moderators=false)
      params.permit.merge({
        handler: handler,
        name: name,
        description: description,
        welcome: '',
        recording: recording,
        wait_moderator: wait_moderator,
        all_moderators: all_moderators
      })
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

    def message_has_custom?(message, type)
      message.has_key?('custom_params') && message['custom_params'].has_key?('custom_' + type) && message['custom_params']['custom_' + type] == 'true'
    end

    def check_for_cancel
      if params[:cancel]
        redirect_to @room
      end
    end

    def resource_handler(params)
      Digest::SHA1.hexdigest('rooms' + params['tool_consumer_instance_guid'] + params['resource_link_id']).to_s
    end

end
