class AddConsumerKeyToRooms < ActiveRecord::Migration[6.0]
  def change
    add_column(:rooms, :consumer_key, :string)
  end
end
