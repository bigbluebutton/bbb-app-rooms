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
    event = build_event(:create)

    begin
      response = RestClient.post(*event)
      payload = JSON.parse(response)

      event_id = payload['CalendarEventId']
      BrightspaceCalendarEvent.create(event_id: event_id,
                                      scheduled_meeting_id: @scheduled_meeting.id,
                                      room_id: @scheduled_meeting.room_id)
    rescue RestClient::ExceptionWithResponse => e
      Rails.logger.error("Could not send calendar event: #{e.response}")
    end
    redirect_to(*pop_redirect_from_session!('brightspace_return_to'))
  end

  def send_update_calendar_event
    event = build_event(:update)

    begin
      RestClient.put(*event)
    rescue RestClient::ExceptionWithResponse => e
      Rails.logger.error("Could not send calendar event: #{e.response}")
    end
    redirect_to(*pop_redirect_from_session!('brightspace_return_to'))
  end

  def send_delete_calendar_event
    event = build_event(:delete)

    begin
      RestClient.delete(*event)

      BrightspaceCalendarEvent.destroy_by(room_id: @room,
                                          scheduled_meeting_id: permitted_params[:id])
    rescue RestClient::ExceptionWithResponse => e
      Rails.logger.error("Could not send calendar event: #{e.response}")
    end
    redirect_to(*pop_redirect_from_session!('brightspace_return_to'))
  end

  private

  def prevent_event_duplication
    event = @scheduled_meeting.brightspace_calendar_event
    return unless event

    Rails.logger.info('Brightspace calendar event already sent.')
    redirect_to(@room)
  end

  def build_event(type)
    omniauth_auth = session['omniauth_auth']['brightspace']
    access_token = omniauth_auth['credentials']['token']
    refresh_token = omniauth_auth['credentials']['refresh_token']

    headers = build_calendar_headers(access_token)
    case type
    when :create, :update
      event_id = @scheduled_meeting.brightspace_calendar_event&.event_id || ''
      calendar_url = build_calendar_url(@app_launch, event_id)
      calendar_payload = build_calendar_payload(@scheduled_meeting)

      event = [calendar_url, calendar_payload.to_json, headers]
    when :delete
      event = BrightspaceCalendarEvent.find_by(room_id: @room,
                                               scheduled_meeting_id: permitted_params[:id])
      event_id = event&.event_id
      return nil unless event_id

      calendar_url = build_calendar_url(@app_launch, event_id)
      event = [calendar_url, headers]
    end
    event
  end

  def set_event
    @custom_params = permitted_params.to_h
    @custom_params[:event] = action_name
  end

  def permitted_params
    params.permit(:room_id, :id, :app_id, :event_id)
  end
end
