# coding: utf-8
class ScheduledMeetingsController < ApplicationController
  include ApplicationHelper
  include BigBlueButtonHelper

  before_action :authenticate_user!, except: %i[external external_post], raise: false
  before_action :find_room
  before_action :find_user, except: %i[external external_post]
  before_action :find_scheduled_meeting, only: %i[edit update join external external_post]

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
    # make user wait until moderator is in room
    if wait_for_mod?(@scheduled_meeting, @user) && !mod_in_room?(@scheduled_meeting)
      render json: { :wait_for_mod => true } , status: :ok
    else
      NotifyRoomWatcherJob.set(wait: 5.seconds).perform_later(@scheduled_meeting)
      redirect_to join_meeting_url(@scheduled_meeting, @user)
    end
  end

  def external
  end

  def external_post
    # TODO: validate the params

    if !mod_in_room?(@scheduled_meeting)
      render json: { :wait_for_mod => true } , status: :ok
    else
      full_name = "#{params[:first_name]} #{params[:last_name]}"
      redirect_to external_join_meeting_url(@scheduled_meeting, full_name)
    end
  end

  private

  def scheduled_meeting_params
    params.require(:scheduled_meeting).permit(
      :name, :recording, :wait_moderator, :all_moderators, :duration
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
