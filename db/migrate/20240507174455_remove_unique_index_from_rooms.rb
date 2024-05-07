# frozen_string_literal: true

class RemoveUniqueIndexFromRooms < ActiveRecord::Migration[6.1]
  def up
    # Remove the existing unique index
    remove_index(:rooms, :code, unique: true, if_exists: true)
    # Add a non-unique index
    add_index(:rooms, :code, name: 'index_rooms_on_code')
  end

  def down
    # Remove the non-unique index
    remove_index(:rooms, name: 'index_rooms_on_code', if_exists: true)
    # Re-add the unique index
    add_index(:rooms, :code, unique: true, name: 'index_rooms_on_code_unique')
  end
end
