class AddHashIdToScheduledMeetings < ActiveRecord::Migration[6.0]
  def change
    add_column :scheduled_meetings, :hash_id, :string
    add_index :scheduled_meetings, :hash_id, unique: true
  end
end
