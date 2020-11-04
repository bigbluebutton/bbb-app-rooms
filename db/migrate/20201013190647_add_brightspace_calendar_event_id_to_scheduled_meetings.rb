class AddBrightspaceCalendarEventIdToScheduledMeetings < ActiveRecord::Migration[6.0]
  def change
    add_column :scheduled_meetings, :brightspace_calendar_event_id, :integer
  end
end
