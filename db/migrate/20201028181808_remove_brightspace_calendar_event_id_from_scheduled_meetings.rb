class RemoveBrightspaceCalendarEventIdFromScheduledMeetings < ActiveRecord::Migration[6.0]
  def change
    remove_column(:scheduled_meetings, :brightspace_calendar_event_id)
  end
end
