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
  before_action :find_room
  before_action :validate_room, except: open_actions
  before_action :find_user

  before_action :find_scheduled_meeting, only: (%i[edit update destroy] + open_actions)
  before_action :validate_scheduled_meeting, only: (%i[edit update destroy] + open_actions)

  before_action only: %i[join external wait] do
    authorize_user!(:show, @scheduled_meeting)
  end
  before_action only: %i[new create edit update destroy] do
    authorize_user!(:edit, @room)
  end

  before_action :delete_blank_repeat, only: %i[create update]

  def new
    @scheduled_meeting = ScheduledMeeting.new(@room.attributes_for_meeting)
  end

  def create
    respond_to do |format|
      # use the attributes from the room as the default
      # then override with the permitted params incoming from the view
      @scheduled_meeting = @room.scheduled_meetings.new(
        @room.attributes_for_meeting.merge(
          scheduled_meeting_params(@room)
        )
      )
      if validate_start_at(@scheduled_meeting)
        @scheduled_meeting.set_dates_from_params(params[:scheduled_meeting])
      end

      room_session = get_room_session(@room)
      @scheduled_meeting.created_by_launch_nonce = room_session['launch'] if room_session.present?

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
      if @scheduled_meeting.update(scheduled_meeting_params(@room))
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
    @is_running = mod_in_room?(@scheduled_meeting)
  end

  def external
    # allow signed in users to use this page, but autofill the inputs
    # and don't let users change them
    if @user.present?
      @first_name = @user.first_name
      @last_name = @user.last_name
    end
    @ended = !@scheduled_meeting.active? && !mod_in_room?(@scheduled_meeting)

    @disclaimer = ConsumerConfig
                    .select(:external_disclaimer)
                    .find_by(key: @room.consumer_key)
                    &.external_disclaimer
  end

  def destroy
    @scheduled_meeting.destroy
    respond_to do |format|
      format.html { redirect_to room_path(@room), notice: t('default.scheduled_meeting.destroyed') }
      format.json { head :no_content }
    end
  end

  private

  # Removes :repeat if it's blank, we want it as null in the database
  def delete_blank_repeat
    if params.key?(:scheduled_meeting) &&
       params[:scheduled_meeting].key?(:repeat) &&
       params[:scheduled_meeting][:repeat].blank?
      params[:scheduled_meeting].delete(:repeat)
    end
  end

  def scheduled_meeting_params(room)
    attrs = [
      :name, :recording, :duration, :description, :welcome, :repeat
    ]
    attrs << [:wait_moderator] if room.allow_wait_moderator
    attrs << [:all_moderators] if room.allow_all_moderators
    params.require(:scheduled_meeting).permit(*attrs)
  end

  def find_scheduled_meeting
    @scheduled_meeting = @room.scheduled_meetings.from_param(params[:id])
  end

  def validate_scheduled_meeting
    if @scheduled_meeting.blank?
      set_error('scheduled_meeting', 'not_found', :not_found)
      respond_to do |format|
        format.html { render 'shared/error', status: @error[:status] }
      end
      false
    end
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
