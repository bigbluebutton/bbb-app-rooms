class CreateScheduledMeetings < ActiveRecord::Migration[6.0]
  def change
    create_table :scheduled_meetings do |t|
      t.references :room
      t.string :name, null: false
      t.datetime :start_at, null: false
      t.integer :duration, null: false
      t.boolean :recording, default: true
      t.boolean :wait_moderator, default: true
      t.boolean :all_moderators, default: false
      t.timestamps
    end
  end
end
