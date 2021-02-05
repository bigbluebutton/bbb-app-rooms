# frozen_string_literal: true

module BrightspaceHelper
  def send_calendar_event(method, app, args)
    case method
    when :create, :update
      scheduled_meeting = args[:scheduled_meeting]

      if scheduled_meeting.brightspace_calendar_event.present?
        # The API doesn't allow to delete the quicklink directly, the only way
        # is by destroying the link that generated the quicklink.
        # So, instead of updating the link, we destroy it, so it destroy the
        # quicklink as well, and then we create it again.
        send_delete_link(app, scheduled_meeting)
      end

      # (re)create link
      lti_link_data = send_create_link(app, scheduled_meeting)

      # (re)create quicklink
      lti_quicklink_data = send_create_quicklink(app,
                                                 scheduled_meeting,
                                                 lti_link_data)
      # update if it exists
      calendar_event_data =
        if scheduled_meeting.brightspace_calendar_event.present?
          send_update_calendar_entry(app, scheduled_meeting, lti_quicklink_data)
        else
          send_create_calendar_entry(app, scheduled_meeting, lti_quicklink_data)
        end

      # Create it the update fails.
      # The update might fail if the calendar event was deleted on the
      # brightspace side but not on our servers.
      update_failed = calendar_event_data.nil?
      if update_failed
        unless scheduled_meeting.brightspace_calendar_event.nil?
          scheduled_meeting.brightspace_calendar_event&.destroy
          # Reload scheduled meeting because it is in an inconsistent state
          # since its BrightspaceCalendarEvent was deleted
          scheduled_meeting.reload
        end

        Rails.logger.warn('Failed to send update calendar entry, ' \
                          'sending create caledar entry instead.')

        calendar_event_data = send_create_calendar_entry(app,
                                                         scheduled_meeting,
                                                         lti_quicklink_data)
      end

      return if calendar_event_data.nil?

      { event_id: calendar_event_data['CalendarEventId'],
        lti_link_id: lti_link_data['LtiLinkId'], }
    when :delete
      scheduled_meeting_id = args[:scheduled_meeting_id]
      room = args[:room]

      # delete calendar entry
      send_delete_calendar_entry(app, scheduled_meeting_id, room)

      # delete link (and quicklink)
      send_delete_link(app, scheduled_meeting_id)
    end
  end

  private

  def send_create_link(app, scheduled_meeting)
    create_link_event = build_event(:create_link,
                                    app,
                                    scheduled_meeting: scheduled_meeting)
    send_event(:create, create_link_event)
  end

  def send_delete_link(app, scheduled_meeting_id)
    delete_link_event = build_event(:delete_link,
                                    app,
                                    scheduled_meeting: scheduled_meeting_id)

    send_event(:delete, delete_link_event)
  end

  def send_create_quicklink(app, scheduled_meeting, lti_link_data)
    create_quicklink_event = build_event(:create_quicklink,
                                         app,
                                         scheduled_meeting: scheduled_meeting,
                                         lti_link_data: lti_link_data)
    send_event(:create, create_quicklink_event)
  end

  def send_create_calendar_entry(app, scheduled_meeting, lti_quicklink_data)
    create_calendar_event = build_event(:create_calendar_entry,
                                        app,
                                        scheduled_meeting: scheduled_meeting,
                                        lti_quicklink_data: lti_quicklink_data)
    send_event(:create, create_calendar_event)
  end

  def send_update_calendar_entry(app, scheduled_meeting, lti_quicklink_data)
    create_calendar_event = build_event(:create_calendar_entry,
                                        app,
                                        scheduled_meeting: scheduled_meeting,
                                        lti_quicklink_data: lti_quicklink_data)
    send_event(:update, create_calendar_event)
  end

  def send_delete_calendar_entry(app, scheduled_meeting_id, room)
    delete_calendar_event = build_event(:delete_calendar_entry,
                                        app,
                                        scheduled_meeting_id: scheduled_meeting_id,
                                        room: room)
    send_event(:delete, delete_calendar_event)
  end

  def build_event(type, app, args)
    omniauth_auth = session['omniauth_auth']['brightspace']
    access_token = omniauth_auth['credentials']['token']
    # refresh_token = omniauth_auth['credentials']['refresh_token']

    headers = build_headers(access_token)

    case type
    when :create_link
      scheduled_meeting = args[:scheduled_meeting]

      url = build_link_url(:create, app)
      payload = build_link_payload(scheduled_meeting)
      event = [url, payload.to_json, headers]
    when :update_link
      scheduled_meeting = args[:scheduled_meeting]

      event = BrightspaceCalendarEvent.find_by(scheduled_meeting_id: scheduled_meeting)
      lti_link_id = event&.link_id

      url = build_link_url(:update, app, lti_link_id)
      payload = build_link_payload(scheduled_meeting)
      event = [url, payload.to_json, headers]
    when :delete_link
      scheduled_meeting = args[:scheduled_meeting]

      event = BrightspaceCalendarEvent.find_by(scheduled_meeting_id: scheduled_meeting)
      lti_link_id = event&.link_id

      url = build_link_url(:delete, app, lti_link_id)
      event = [url, headers]
    when :create_quicklink
      lti_link_data = args[:lti_link_data]

      url = build_quicklink_url(app, lti_link_data['LtiLinkId'])
      payload = {}
      event = [url, payload.to_json, headers]
    when :create_calendar_entry, :update_calendar_entry
      scheduled_meeting = args[:scheduled_meeting]
      lti_quicklink_data = args[:lti_quicklink_data]
      event_id = scheduled_meeting.brightspace_calendar_event&.event_id || ''

      url = build_calendar_url(app, event_id)
      domain = app.brightspace_oauth.url
      public_url = lti_quicklink_data['PublicUrl']
                   .sub('{orgUnitId}', app.context_id)
      quicklink_url = "#{domain}#{public_url}"
      payload = build_calendar_payload(scheduled_meeting, quicklink_url)
      event = [url, payload.to_json, headers]
    when :delete_calendar_entry
      scheduled_meeting_id = args[:scheduled_meeting_id]
      room = args[:room]

      # Even though scheduled_meeting_id is unique, it's important to filter
      # by room_id, so an authorized person can't delete an event from another
      # room
      event = BrightspaceCalendarEvent.find_by(room_id: room,
                                               scheduled_meeting_id: scheduled_meeting_id)
      event_id = event&.event_id
      return nil unless event_id

      url = build_calendar_url(app, event_id)
      event = [url, headers]
    end
    event
  end

  def send_event(method, event)
    action = case method
             when :create
               :post
             when :update
               :put
             when :delete
               :delete
             end
    response = RestClient.send(action, *event)
    JSON.parse(response) if response.present?
  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.warn("Failed to send #{method} event: #{e.message}")
    response = nil
  end

  def build_link_url(method, app, lti_link_id = '')
    brightspace_oauth = app.brightspace_oauth
    domain = brightspace_oauth.url
    version = '1.48'
    case method
    when :create
      org_unit = app.context_id
      "#{domain}/d2l/api/le/#{version}/lti/link/#{org_unit}"
    when :delete, :update
      "#{domain}/d2l/api/le/#{version}/lti/link/#{lti_link_id}"
    end
  end

  def build_link_payload(scheduled_meeting)
    lti_url = omniauth_bbbltibroker_url('/rooms/messages/blti')
    payload = {
      Title: "Elos Room #{scheduled_meeting.id}",
      Url: lti_url,
      Description: '',
      Key: '',
      PlainSecret: nil,
      IsVisible: true,
      SignMessage: true,
      SignWithTc: true,
      SendTcInfo: true,
      SendContextInfo: true,
      SendUserId: true,
      SendUserName: true,
      SendUserEmail: true,
      SendLinkTitle: true,
      SendLinkDescription: true,
      SendD2LUserName: true,
      SendD2LOrgDefinedId: true,
      SendD2LOrgRoleId: true,
      UseToolProviderSecuritySettings: true,
      CustomParameters: [
        { Name: 'custom_scheduled_meeting',
          Value: scheduled_meeting.id, },
      ],
    }
    payload
  end

  def build_quicklink_url(app, lti_link_id)
    brightspace_oauth = app.brightspace_oauth
    domain = brightspace_oauth.url
    version = '1.48'
    org_unit = app.context_id
    "#{domain}/d2l/api/le/#{version}/lti/quicklink/#{org_unit}/#{lti_link_id}"
  end

  def build_calendar_url(app, event_id = '')
    brightspace_oauth = app.brightspace_oauth
    domain = brightspace_oauth.url
    version = '1.48'
    org_unit = app.context_id
    "#{domain}/d2l/api/le/#{version}/#{org_unit}/calendar/event/#{event_id}"
  end

  def build_calendar_payload(scheduled_meeting, quicklink_url)
    repeat_type, repeat_every = calendar_repeat_type(scheduled_meeting.repeat)
    weak_day = scheduled_meeting.start_at.wday

    title = scheduled_meeting.name
    description = build_description(scheduled_meeting.description, quicklink_url)
    start_date_time = scheduled_meeting.start_at
    end_date_time = (start_date_time + scheduled_meeting.duration)

    # 2 years seems to be the limit value that brightspace accepts
    repeat_until_date = start_date_time.next_year(2)

    recurrence_info = if repeat_type > 1
                        {
                          RepeatType: repeat_type,
                          RepeatEvery: repeat_every,
                          RepeatOnInfo: {
                            Monday: weak_day == 1,
                            Tuesday: weak_day == 2,
                            Wednesday: weak_day == 3,
                            Thursday: weak_day == 4,
                            Friday: weak_day == 5,
                            Saturday: weak_day == 6,
                            Sunday: weak_day == 7,
                          },
                          RepeatUntilDate: repeat_until_date.utc,
                        }
                      end

    calendar_payload = {
      Title: title,
      Description: description,
      StartDateTime: start_date_time.utc,
      EndDateTime: end_date_time.utc,
      StartDay: nil,
      EndDay: nil,
      GroupId: nil,
      RecurrenceInfo: recurrence_info,
      LocationId: nil,
      LocationName: '',
      AssociatedEntity: nil,
      VisibilityRestrictions: {
        Type: 1,
        Range: nil,
        HiddenRangeUnitType: nil,
        StartDate: nil,
        EndDate: nil,
      },
    }

    calendar_payload
  end

  def build_description(description, quicklink_url)
    link_text = t('default.scheduled_meeting.calendar.description.link')
    link = "<a href=\"#{quicklink_url}\" target=\"_blank\">#{link_text}</a>"
    description = "#{link}\n#{description}"

    # Split each line into paragraphs
    description.split("\n").map { |line| "<p>#{line}</p>" }.join
  end

  def calendar_repeat_type(repeat)
    return [1, 0] unless repeat

    case repeat
    when 'weekly'
      [3, 1]
    when 'every_two_weeks'
      [3, 2]
    else
      [1, 0]
    end
  end

  def build_headers(access_token)
    { Authorization: "Bearer #{access_token}",
      content_type: :json,
      accept: :json, }
  end
end
