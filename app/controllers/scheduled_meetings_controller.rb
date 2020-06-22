class ScheduledMeetingsController < ApplicationController
  include ApplicationHelper
  include BigBlueButtonHelper
  before_action :authenticate_user!, raise: false
  before_action :set_room

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
  end

  def join
    # make user wait until moderator is in room
    if wait_for_mod? && !mod_in_room?
      render json: { :wait_for_mod => true } , status: :ok
    else
      NotifyRoomWatcherJob.set(wait: 5.seconds).perform_later(@room)
      redirect_to join_meeting_url
    end
  end

  private

  def scheduled_meeting_params
    params.require(:scheduled_meeting).permit(
      :name
    )
  end

  def set_room
    @room = Room.find_by(id: params[:room_id])
    return unless check_room
    find_user
  end
end
