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

  # GET /launch?name=&description=&handler=
  # GET /launch.json?
  def launch
    respond_to do |format|
      if @room
        format.html { render :show }
        format.json { render :show, status: :created, location: @room }
      else
        format.html { render :error }
        format.json { render json: @error, status: :unprocessable_entity }
      end
    end
  end

  # GET /rooms/:id/meeting/join
  # GET /rooms/:id/meeting/join.json
  def meeting_join
    redirect_to join_meeting_url
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

  private

    def set_error(error, status)
      @room = @user = nil
      @error = { key: t("error.room.#{error}.code"), message:  t("error.room.#{error}.message"), suggestion: t("error.room.#{error}.suggestion"), :status => status }
    end

    def authenticate_user!
      return unless omniauth_provider?(:bbbltibroker)
      # Assume user authenticated if session[:uid] is set
      return if session[:uid]
      if params['action'] == 'launch'
        cookies['launch_params'] = { :value => params.except(:app, :controller, :action).to_json, :expires => 30.minutes.from_now }
        redirect_to omniauth_authorize_path(:bbbltibroker) and return
      end
      redirect_to errors_path(401)
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_room
      @error = nil
      @room = Room.find_by(id: params[:id])
      # Exit with error if room was not found
      set_error('notfound', :not_found) and return unless @room
      # Exit by setting the user as Administrator if bbbltibroker is not enabled
      unless omniauth_provider?(:bbbltibroker)
        @user = User.new({uid: 0, roles: 'Administrator', full_name: 'User'})
        return
      end
      # Exit with error by re-setting the room to nil if the cookie for the room.handler is not set
      set_error('forbidden', :forbidden) and return unless cookies[@room.handler]
      # Continue through happy path
      launch_params = JSON.parse(cookies[@room.handler])
      @user = User.new(user_params(launch_params))
    end

    def set_launch_room
      @error = nil
      sso = JSON.parse(RestClient.get("#{lti_broker_api_v1_sso_url}/launches/#{params['token']}", {'Authorization' => "Bearer #{omniauth_client_token}"}))
      # Exit with error if sso is not valid
      set_error('forbidden', :forbidden) and return unless sso["valid"]
      # Continue through happy path
      launch_params = sso["message"]
      @room = Room.find_by(handler: params[:handler]) || Room.create!(new_room_params(launch_params['resource_link_title'], launch_params['resource_link_description']))
      @user = User.new(user_params(launch_params))
      cookies[params[:handler]] = { :value => launch_params.to_json, :expires => 30.minutes.from_now }
    end

    def room_params
      params.require(:room).permit(:name, :description, :welcome, :moderator, :viewer, :recording, :wait_moderator, :all_moderators)
    end

    def user_params(launch_params)
      {
        uid: launch_params['user_id'],
        roles: launch_params['roles'],
        full_name: launch_params['lis_person_name_full'],
        first_name: launch_params['lis_person_name_given'],
        last_name: launch_params['lis_person_name_family'],
        email: launch_params['lis_person_contact_email_primary'],
      }
    end

    def new_room_params(name, description)
      params.permit(:handler).merge({
        name: name,
        description: description,
        welcome: '',
        recording: false,
        wait_moderator: false,
        all_moderators: false
      })
    end

    def check_for_cancel
      if params[:cancel]
        redirect_to @room
      end
    end

end
