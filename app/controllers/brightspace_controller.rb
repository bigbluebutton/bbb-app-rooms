require 'brightspace_helper'

class BrightspaceController < ApplicationController
  include ApplicationHelper
  include BrightspaceHelper

  # make sure the user has access to the room and meeting
  before_action :find_room
  before_action :validate_room
  before_action :find_user
  before_action :find_scheduled_meeting
  before_action :validate_scheduled_meeting
  before_action -> { authorize_user!(:edit, @room) }, only: :send_calendar_event
  before_action :prevent_event_duplication, only: :send_calendar_event

  before_action -> {
    params = {
      room: @room.to_param,
      scheduled_meeting: @scheduled_meeting.to_param
    }
    authenticate_with_oauth! :brightspace, params
  }, only: :send_calendar_event, raise: false

  def send_calendar_event
    calendar_url = build_calendar_url(@scheduled_meeting)
    calendar_payload = build_calendar_payload(@scheduled_meeting)

    omniauth_auth = session['omniauth_auth']['brightspace']
    access_token = omniauth_auth['credentials']['token']
    refresh_token = omniauth_auth['credentials']['refresh_token']

    headers = build_calendar_headers(access_token)

    event = [calendar_url, calendar_payload.to_json, headers]

    begin
      response = RestClient.post(*event)
      payload = JSON.parse(response)

      event_id = payload['CalendarEventId']
      @scheduled_meeting.update(brightspace_calendar_event_id: event_id)
    rescue RestClient::ExceptionWithResponse => e
      Rails.logger.error "Could not send calendar event: #{e.response}"
    end

    redirect_to @room, notice: t('default.scheduled_meeting.created')
  end

  private

  def prevent_event_duplication
    event_id = @scheduled_meeting.brightspace_calendar_event_id
    if event_id
      Rails.logger.info "Brightspace calendar event #{event_id} already sent."
      redirect_to @room
    end
  end
end
