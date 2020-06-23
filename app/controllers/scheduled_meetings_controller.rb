class ScheduledMeetingsController < ApplicationController
  include ApplicationHelper
  include BigBlueButtonHelper
  before_action :authenticate_user!, raise: false
  before_action :find_room
  before_action :find_scheduled_meeting, only: [:edit, :update, :join]

  def new
    @scheduled_meeting = ScheduledMeeting.new
  end

  def create
    @scheduled_meeting = @room.scheduled_meetings.create(scheduled_meeting_params)
    respond_to do |format|
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
      NotifyRoomWatcherJob.set(wait: 5.seconds).perform_later(@room)
      redirect_to join_meeting_url(@scheduled_meeting, @user)
    end
  end

  private

  def scheduled_meeting_params
    params.require(:scheduled_meeting).permit(
      :name
    )
  end

  def find_room
    @room = Room.from_param(params[:room_id])
    return unless check_room
    find_user
  end

  def find_scheduled_meeting
    @scheduled_meeting = ScheduledMeeting.from_param(params[:id])
  end
end
