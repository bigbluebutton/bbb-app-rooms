module BrightspaceHelper
  def build_calendar_url(app, event_id='')
    brightspace_oauth = app.brightspace_oauth
    domain = brightspace_oauth.url
    version = "1.34"
    org_unit = app.context_id
    "#{domain}/d2l/api/le/#{version}/#{org_unit}/calendar/event/#{event_id}"
  end

  def build_calendar_payload(scheduled_meeting)
    repeat_type, repeat_every = calendar_repeat_type scheduled_meeting.repeat
    weak_day = scheduled_meeting.start_at.wday

    title = scheduled_meeting.name
    description = scheduled_meeting.description
    start_date_time = scheduled_meeting.start_at
    end_date_time = (start_date_time+scheduled_meeting.duration)

    # 2 years seems to be the limit value that brightspace accepts
    repeat_until_date = start_date_time.next_year 2

    recurrence_info = repeat_type == 1 ? nil : {
      RepeatType: repeat_type,
      RepeatEvery: repeat_every,
      RepeatOnInfo: {
        Monday:    weak_day == 1,
        Tuesday:   weak_day == 2,
        Wednesday: weak_day == 3,
        Thursday:  weak_day == 4,
        Friday:    weak_day == 5,
        Saturday:  weak_day == 6,
        Sunday:    weak_day == 7
      },
      RepeatUntilDate: repeat_until_date.utc
    }

    description = add_visit_message_to(description)

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
      LocationName: "",
      AssociatedEntity: nil,
      VisibilityRestrictions: {
        Type: 1,
        Range: nil,
        HiddenRangeUnitType: nil,
        StartDate: nil,
        EndDate: nil
      }
    }

    calendar_payload
  end

  def build_calendar_headers(access_token)
    {
      Authorization: "Bearer #{access_token}",
      content_type: :json,
      accept: :json
    }
  end

  private

  def calendar_repeat_type(repeat)
    return [1, 0] unless repeat
    case repeat
    when "weekly"
      [3, 1]
    when "every_two_weeks"
      [3, 2]
    else
      [1, 0]
    end
  end

  def add_visit_message_to(description)
    t('default.scheduled_meeting.calendar.description.visit') +
    "\n" +
    description
  end
end
