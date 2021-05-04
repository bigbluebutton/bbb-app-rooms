class AddRepeatOnScheduledMeetings < ActiveRecord::Migration[6.0]
  def change
    add_column(:scheduled_meetings, :repeat, :string)
    add_index(:scheduled_meetings, :repeat)
  end
end
