require 'brightspace_helper'

class BrightspaceController < ApplicationController
  include ApplicationHelper
  include BrightspaceHelper

  # make sure the user has access to the room and meeting
  before_action :find_room
  before_action :validate_room
  before_action :find_user
  before_action :find_scheduled_meeting, except: :send_delete_calendar_event
  before_action :validate_scheduled_meeting, except: :send_delete_calendar_event
  before_action -> { authorize_user!(:edit, @room) }
  before_action :prevent_event_duplication, only: :send_create_calendar_event
  before_action :find_app_launch
  before_action :set_event
  before_action -> { authenticate_with_oauth! :brightspace, @custom_params }

  def send_create_calendar_event
    event_data = send_calendar_event(:create,
                                     @app_launch,
                                     scheduled_meeting: @scheduled_meeting)

    if event_data.nil?
      Rails.logger.warn('Failed to receive send_create_calendar_event data, ' \
                        'not creating BrightspaceCalendarEvent on DB.')
    else
      local_params = { event_id: event_data[:event_id],
                      link_id: event_data[:lti_link_id],
                      scheduled_meeting_id: @scheduled_meeting.id,
                      room_id: @scheduled_meeting.room_id, }
      BrightspaceCalendarEvent.find_or_create_by(local_params)
    end

    redirect_to(*pop_redirect_from_session!('brightspace_return_to'))
  end

  def send_update_calendar_event
    event_data = send_calendar_event(:update,
                                     @app_launch,
                                     scheduled_meeting: @scheduled_meeting)
    if event_data.nil?
      Rails.logger.warn('Failed to receive send_update_calendar_event data, ' \
                        'not updating BrightspaceCalendarEvent on DB.')
    else
      local_params = { event_id: event_data[:event_id],
                       link_id: event_data[:lti_link_id],
                       room_id: @scheduled_meeting.room_id, }
      BrightspaceCalendarEvent
        .find_or_create_by(scheduled_meeting_id: @scheduled_meeting.id)
        &.update(local_params)
    end

    redirect_to(*pop_redirect_from_session!('brightspace_return_to'))
  end

  def send_delete_calendar_event
    send_calendar_event(:delete,
                        @app_launch,
                        scheduled_meeting_id: permitted_params[:id],
                        room: @room)
    BrightspaceCalendarEvent
      .find_by(scheduled_meeting_id: permitted_params[:id],
               room_id: @room.id)
      &.delete

    redirect_to(*pop_redirect_from_session!('brightspace_return_to'))
  end

  private

  def prevent_event_duplication
    event = @scheduled_meeting.brightspace_calendar_event
    return unless event

    Rails.logger.info('Brightspace calendar event already sent.')
    redirect_to(@room)
  end

  def set_event
    @custom_params = permitted_params.to_h
    @custom_params[:event] = action_name
  end

  def permitted_params
    params.permit(:room_id, :id, :app_id, :event_id)
  end
end
