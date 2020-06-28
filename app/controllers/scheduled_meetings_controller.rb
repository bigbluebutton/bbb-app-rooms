# coding: utf-8
# frozen_string_literal: true

require 'user'
require 'bbb_api'

class ScheduledMeetingsController < ApplicationController
  include ApplicationHelper
  include BbbApi
  include BbbAppRooms

  # actions that can be accessed without a session, without the LTI launch
  open_actions = %i[external wait join]

  # validate the room/session only for routes that are not open
  before_action :find_and_validate_room, except: open_actions
  before_action :find_room, only: open_actions

  # some actions throw a 401 when the user is not found/valid
  # others just search for a user but are open to unauthenticated access
  before_action :authenticate_user!, except: open_actions, raise: false
  before_action :find_user

  before_action :find_scheduled_meeting, only: (%i[edit update destroy] + open_actions)

  before_action only: %i[join external wait] do
    authorize_user!(:show, @scheduled_meeting)
  end
  before_action only: %i[new create edit update destroy] do
    authorize_user!(:edit, @room)
  end

  def new
    @scheduled_meeting = ScheduledMeeting.new
  end

  def create
    respond_to do |format|
      @scheduled_meeting = @room.scheduled_meetings.create(scheduled_meeting_params)
      if validate_start_at(@scheduled_meeting)
        @scheduled_meeting.set_dates_from_params(params[:scheduled_meeting])
      end
      if @scheduled_meeting.save
        format.html { redirect_to @room, notice: t('default.scheduled_meeting.created') }
      else
        format.html { render :new }
      end
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if validate_start_at(@scheduled_meeting)
        @scheduled_meeting.set_dates_from_params(params[:scheduled_meeting])
      end
      if @scheduled_meeting.update(scheduled_meeting_params)
        format.html { redirect_to @room, notice: t('default.scheduled_meeting.updated') }
      else
        format.html { render :edit }
      end
    end
  end

  def join
    # if there's a user signed in, always use their info
    # only way for a meeting to be created is through here
    if @user.present?

      # make user wait until moderator is in room
      if wait_for_mod?(@scheduled_meeting, @user) && !mod_in_room?(@scheduled_meeting)
        redirect_to wait_room_scheduled_meeting_path(@room, @scheduled_meeting)
      else
        # join as moderator (start the meeting) and notify users
        NotifyRoomWatcherJob.set(wait: 10.seconds).perform_later(@scheduled_meeting)
        redirect_to join_api_url(@scheduled_meeting, @user)
      end

    # no signed in user, expects identification parameters in the url and join
    # the user always as guest
    else
      if params[:first_name].blank? || params[:first_name].strip.blank? ||
         params[:last_name].blank? || params[:last_name].strip.blank?
        redirect_to external_room_scheduled_meeting_path(@room, @scheduled_meeting)
        return
      end

      if !mod_in_room?(@scheduled_meeting)
        redirect_to wait_room_scheduled_meeting_path(
                      @room, @scheduled_meeting,
                      first_name: params[:first_name], last_name: params[:last_name]
                    )
      else
        # join as guest
        name = "#{params[:first_name]} #{params[:last_name]}"
        redirect_to external_join_api_url(@scheduled_meeting, name)
      end
    end
  end

  def wait
    # no user in the session and no name set, go back to the external join page
    if @user.nil? && (params[:first_name].blank? || params[:last_name].blank?)
      redirect_to external_room_scheduled_meeting_path(@room, @scheduled_meeting)
      return
    end

    # users with a session and anonymous users can wait in this page
    # decide here where they will go to when the meeting starts
    if @user.present?
      @full_name = @user.full_name
      @post_to = join_room_scheduled_meeting_path(@room, @scheduled_meeting)
    else
      @full_name = "#{params[:first_name]} #{params[:last_name]}"
      @post_to = join_room_scheduled_meeting_path(
        @room, @scheduled_meeting,
        first_name: params[:first_name], last_name: params[:last_name]
      )
    end
  end

  def external
    # allow signed in users to use this page, but autofill the inputs
    # and don't let users change them
    if @user.present?
      @first_name = @user.first_name
      @last_name = @user.last_name
    end
  end

  def destroy
    @scheduled_meeting.destroy
    respond_to do |format|
      format.html { redirect_to room_path(@room), notice: t('default.scheduled_meeting.destroyed') }
      format.json { head :no_content }
    end
  end

  private

  def scheduled_meeting_params
    params.require(:scheduled_meeting).permit(
      :name, :recording, :wait_moderator, :all_moderators, :duration, :description, :welcome
    )
  end

  def find_scheduled_meeting
    @scheduled_meeting = ScheduledMeeting.from_param(params[:id])
  end

  def validate_start_at(scheduled_meeting)
    begin
      ScheduledMeeting.parse_start_at(
        params[:scheduled_meeting][:date], params[:scheduled_meeting][:time]
      )
      true
    rescue Date::Error
      scheduled_meeting.start_at = nil
      scheduled_meeting.errors.add(:start_at, t('default.scheduled_meeting.error.invalid_start_at'))
      false
    end
  end
end
