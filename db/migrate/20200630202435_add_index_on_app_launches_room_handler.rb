class AddIndexOnAppLaunchesRoomHandler < ActiveRecord::Migration[6.0]
  def change
    add_index(:app_launches, :room_handler)
  end
end
