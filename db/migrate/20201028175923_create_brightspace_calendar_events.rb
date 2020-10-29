class CreateBrightspaceCalendarEvents < ActiveRecord::Migration[6.0]
  def change
    create_table :brightspace_calendar_events do |t|
      t.integer :event_id
      t.references :scheduled_meeting, foreign_key: false
      # room is purposefully redundant, it is used to validate the event after
      # the scheduled meeting is removed.
      t.references :room, foreign_key: true

      t.timestamps
    end

    add_index :brightspace_calendar_events, [:event_id, :scheduled_meeting_id, :room_id], unique: true, name: 'idx_brightspace_calendar_events_event_scheduled_meeting_room'
  end
end

