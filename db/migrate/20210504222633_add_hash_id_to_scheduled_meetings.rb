class AddHashIdToScheduledMeetings < ActiveRecord::Migration[6.0]
  def up
    add_column :scheduled_meetings, :hash_id, :string
    add_index :scheduled_meetings, :hash_id, unique: true

    ScheduledMeeting.find_each do |s|
      s.set_hash_id
      s.save
    end
  end

  def down
    remove_column :scheduled_meetings, :hash_id, :string
    remove_index :scheduled_meetings, :hash_id
  end
end
