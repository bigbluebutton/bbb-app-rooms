class CreateScheduledMeetings < ActiveRecord::Migration[6.0]
  def change
    create_table :scheduled_meetings do |t|
      t.references :room
      t.string :name
      t.datetime :start_at
      t.datetime :end_at
      t.boolean :recording, default: true
      t.boolean :wait_moderator, default: true
      t.boolean :all_moderators, default: false
      t.timestamps
    end
  end
end
