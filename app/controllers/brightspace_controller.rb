class BrightspaceController < ApplicationController
  include ApplicationHelper
  include BrightspaceHelper

  before_action -> {
    authenticate_with_oauth! :brightspace,
      { scheduled_meeting: params['scheduled_meeting_id'] }
  }, only: :send_calendar_event, raise: false

  def send_calendar_event
    scheduled_meeting_id = params['scheduled_meeting_id']
    scheduled_meeting = ScheduledMeeting.find scheduled_meeting_id
    calendar_url = build_calendar_url(scheduled_meeting)
    calendar_payload = build_calendar_payload(scheduled_meeting)

    omniauth_auth = session['omniauth_auth']['brightspace']
    access_token = omniauth_auth['credentials']['token']
    refresh_token = omniauth_auth['credentials']['refresh_token']

    headers = build_calendar_headers(access_token)

    event = [calendar_url, calendar_payload.to_json, headers]

    begin
      response = RestClient.post(*event)
      payload = JSON.parse(response)

      event_id = payload['CalendarEventId']
      scheduled_meeting.update(brightspace_calendar_event_id: event_id)
    rescue RestClient::ExceptionWithResponse => e
      Rails.logger.error "Could not send calendar event: #{e.response}"
    end

    room = scheduled_meeting.room
    redirect_to room, notice: t('default.scheduled_meeting.created')
  end
end
