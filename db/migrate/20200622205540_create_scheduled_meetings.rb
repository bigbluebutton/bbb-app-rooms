class CreateScheduledMeetings < ActiveRecord::Migration[6.0]
  def change
    create_table :scheduled_meetings do |t|
      t.references :room
      t.string :name
      t.datetime :start_at
      t.datetime :end_at

      t.timestamps
    end
  end
end
