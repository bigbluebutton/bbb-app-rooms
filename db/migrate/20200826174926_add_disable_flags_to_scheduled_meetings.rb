class AddDisableFlagsToScheduledMeetings < ActiveRecord::Migration[6.0]
  def change
    add_column(:scheduled_meetings, :disable_external_link, :boolean, default: false)
    add_column(:scheduled_meetings, :disable_private_chat, :boolean, default: false)
    add_column(:scheduled_meetings, :disable_note, :boolean, default: false)
  end
end
