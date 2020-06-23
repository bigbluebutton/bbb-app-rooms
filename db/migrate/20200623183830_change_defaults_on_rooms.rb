class ChangeDefaultsOnRooms < ActiveRecord::Migration[6.0]
  def change
    change_column :rooms, :recording, :boolean, default: true
    change_column :rooms, :wait_moderator, :boolean, default: true
    change_column :rooms, :all_moderators, :boolean, default: false
  end
end
