class AddCreatedByLaunchNonceToScheduledMeetings < ActiveRecord::Migration[6.0]
  def change
    add_column(:scheduled_meetings, :created_by_launch_nonce, :string)
    add_index(:scheduled_meetings, :created_by_launch_nonce)
  end
end
