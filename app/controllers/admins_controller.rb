# frozen_string_literal: true

class AdminsController < ApplicationController
  include Pagy::Backend
  include BbbHelper
  include BbbServer

  before_action :verify_user
  before_action :verify_admin_of_user

  def home
    redirect_to(admins_users_path)
  end

  def users
    @users = AdminpgUser.all
  end

  def delete_user
    if params[:username].nil?
      flash[:notice] = 'There is no username'
      redirect_to(admins_users_path)
      return
    end
    user = User.find_by(username: params[:username])
    if user.nil?
      flash[:notice] = 'There is no existing user'
      redirect_to(admins_users_path)
      return
    end
    user.delete
    flash[:notice] = 'Successfully deleted!'
    redirect_to(admins_users_path)
  end

  # GET /admins/rooms
  def server_rooms
    @rooms = Room.all
    @rooms = [] if @rooms.nil?

    @rooms.sort_by(&:id)
  end

  def server_recordings
    @search = params[:room_handler] || ''
    @recordings = all_recordings(@search)
  end

  # POST /admins/record/:record_id/unpublish
  def recording_unpublish
    unpublish_server_recording(params[:record_id])
    redirect_to(admins_recordings_path)
  end

  # POST /admins/record/:record_id/publish
  def recording_publish
    publish_server_recording(params[:record_id])
    redirect_to(admins_recordings_path)
  end

  # POST /admins/record/:record_id/protect
  def recording_protect
    update_server_recording(params[:record_id], protect: true)
    redirect_to(admins_recordings_path)
  end

  # POST /admins/record/:record_id/unprotect
  def recording_unprotect
    update_server_recording(params[:record_id], protect: false)
    redirect_to(admins_recordings_path)
  end

  # POST /admins/record/:record_id/update
  def recording_update
    if params[:setting] == 'rename_recording'
      update_server_recording(params[:record_id], 'meta_name' => params[:record_name])
    elsif params[:setting] == 'describe_recording'
      update_server_recording(params[:record_id], 'meta_description' => params[:record_description])
    end
  end

  # POST /admins/recordings/:record_id/delete
  def recording_delete
    delete_server_recording(params[:record_id])
    redirect_to(admins_recordings_path)
  end

  # POST /admins/room/:room_id/delete
  def room_delete
    Room.find(params[:room_id]).destroy unless params[:room_id].nil?
    redirect_to(admins_rooms_path)
  end

  # GET /admins/room_configuration
  # TODO
  def room_configuration; end

  # POST /admins/update_room_configuration
  # TODO
  def update_room_configuration; end

  helper_method :recording_date, :recording_length

  private

  def verify_user
    redirect_to(login_path) unless current_user
  end

  def verify_admin_of_user
    redirect_to(login_path) unless current_user.admin?
  end
end
