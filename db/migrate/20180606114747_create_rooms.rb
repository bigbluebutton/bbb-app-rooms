class CreateRooms < ActiveRecord::Migration[5.2]
  def change
    create_table :rooms do |t|
      t.string :name
      t.string :description
      t.string :welcome
      t.string :moderator
      t.string :viewer
      t.boolean :recording
      t.boolean :wait_moderator
      t.boolean :all_moderators

      t.timestamps
    end
  end
end
