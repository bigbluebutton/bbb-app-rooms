class AddMeetingHandlerToRooms < ActiveRecord::Migration[5.2]
  def change
    add_column :rooms, :handler, :string
    add_index :rooms, :handler
  end
end
