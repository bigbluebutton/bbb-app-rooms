class AddLinkIdToBrightspaceCalendarEvents < ActiveRecord::Migration[6.0]
  def change
    add_column :brightspace_calendar_events, :link_id, :integer

    add_index :brightspace_calendar_events, [:link_id, :room_id], unique: true
  end
end
