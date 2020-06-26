class AddDescriptionAndWelcomeToScheduledMeetings < ActiveRecord::Migration[6.0]
  def change
    add_column(:scheduled_meetings, :description, :string)
    add_column(:scheduled_meetings, :welcome, :string)
  end
end
