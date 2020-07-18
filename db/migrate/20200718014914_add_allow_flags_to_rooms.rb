class AddAllowFlagsToRooms < ActiveRecord::Migration[6.0]
  def change
    add_column(:rooms, :allow_wait_moderator, :boolean, default: true)
    add_column(:rooms, :allow_all_moderators, :boolean, default: true)
  end
end
