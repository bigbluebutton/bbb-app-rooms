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
  before_action :find_app_launch, only: %i[create update destroy]

  before_action :find_scheduled_meeting, only: (%i[edit update destroy] + open_actions)
  before_action :validate_scheduled_meeting, only: (%i[edit update destroy] + open_actions)

  before_action only: %i[join external wait] do
    authorize_user!(:show, @scheduled_meeting)
  end
  before_action only: %i[new create edit update destroy] do
    authorize_user!(:edit, @room)
  end

  before_action :set_blank_repeat_as_nil, only: %i[create update]

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
        format.html do
          return_path = room_path(@room), { notice: t('default.scheduled_meeting.created') }
          redirect_if_brightspace(return_path) || redirect_to(*return_path)
        end
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
        format.html do
          return_path = room_path(@room), { notice: t('default.scheduled_meeting.updated') }
          redirect_if_brightspace(return_path) || redirect_to(*return_path)
        end
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
        # notify users if cable is enabled
        if Rails.application.config.cable_enabled
          NotifyRoomWatcherJob.set(wait: 10.seconds).perform_later(@scheduled_meeting)
        end

        # join as moderator (creates the meeting if not created yet)
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

    # if this flag is set in the session, wait a short while and try to join again
    # this happens when users try to create a meeting that's already being created
    auto = get_from_room_session(@room, 'auto_join')
    if auto.present?
      remove_from_room_session(@room, 'auto_join')
      @auto_join = true
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
    # If the external link is disabled, users should get an error
    # if they are not signed in
    if @scheduled_meeting.disable_external_link && @user.blank?
      redirect_to errors_path(404)
    end

    # allow signed in users to use this page, but autofill the inputs
    # and don't let users change them
    if @user.present?
      @first_name = @user.first_name
      @last_name = @user.last_name
    end

    @scheduled_meeting.update_to_next_recurring_date

    @ended = !@scheduled_meeting.active? && !mod_in_room?(@scheduled_meeting)

    @disclaimer = ConsumerConfig
                    .select(:external_disclaimer)
                    .find_by(key: @room.consumer_key)
                    &.external_disclaimer
  end

  def destroy
    event_id = @scheduled_meeting.brightspace_calendar_event&.event_id
    if event_id
      Rails.logger.info('Found brightspace event, sending delete calendar event')

      return_path = room_path(@room), { notice: t('default.scheduled_meeting.destroyed') }
      redirect_if_brightspace(return_path) || redirect_to(*return_path)
    else
      Rails.logger.info('Brightspace event not found')
      respond_to do |format|
        format.html { redirect_to room_path(@room), notice: t('default.scheduled_meeting.destroyed') }
        format.json { head :no_content }
      end
    end
    @scheduled_meeting.destroy
  end

  private

  # Sets :repeat as nil if it's blank. We want it as nil in the database in order
  # for a non-recurring meeting to work
  def set_blank_repeat_as_nil
    if params.dig(:scheduled_meeting, :repeat)&.blank?
      params[:scheduled_meeting][:repeat] = nil
    end
  end

  def scheduled_meeting_params(room)
    attrs = [
      :name, :recording, :duration, :description, :welcome, :repeat,
      :disable_external_link, :disable_private_chat, :disable_note
    ]
    attrs << [:wait_moderator] if room.allow_wait_moderator
    attrs << [:all_moderators] if room.allow_all_moderators
    params.require(:scheduled_meeting).permit(*attrs)
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

  def redirect_if_brightspace(return_path)
    if @app_launch.brightspace_oauth
      Rails.logger.info('Found brightspace, sending calendar event')
      push_redirect_to_session!('brightspace_return_to', *return_path)
      case action_name
      when 'create'
        redirect_to(send_create_calendar_event_room_scheduled_meeting_path(@room, @scheduled_meeting))
      when 'update'
        redirect_to(send_update_calendar_event_room_scheduled_meeting_path(@room, @scheduled_meeting))
      when 'destroy'
        redirect_to(send_delete_calendar_event_room_scheduled_meeting_path(@room, @scheduled_meeting))
      end
      true
    else
      Rails.logger.info('Brightspace not found')
      false
    end
  end
end
