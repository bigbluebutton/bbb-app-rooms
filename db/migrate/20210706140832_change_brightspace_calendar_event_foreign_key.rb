class ChangeBrightspaceCalendarEventForeignKey < ActiveRecord::Migration[6.0]
  def up
    change_column :brightspace_calendar_events, :scheduled_meeting_id, :string
    rename_column :brightspace_calendar_events,
                  :scheduled_meeting_id,
                  :scheduled_meeting_hash_id

    query = <<-SQL
      UPDATE brightspace_calendar_events
      SET scheduled_meeting_hash_id = scheduled_meetings.hash_id
      FROM scheduled_meetings
      WHERE scheduled_meeting_hash_id = CAST (scheduled_meetings.id AS TEXT)
    SQL

    execute(query)
  end

  def down
    query = <<-SQL
      UPDATE brightspace_calendar_events
      SET scheduled_meeting_hash_id = CAST (scheduled_meetings.id AS TEXT)
      FROM scheduled_meetings
      WHERE scheduled_meeting_hash_id = scheduled_meetings.hash_id
    SQL

    execute(query)

    rename_column :brightspace_calendar_events,
                  :scheduled_meeting_hash_id,
                  :scheduled_meeting_id
    change_column :brightspace_calendar_events,
                  :scheduled_meeting_id,
                  'bigint USING scheduled_meeting_id::bigint'
  end
end
