# frozen_string_literal: true

class AddColumnsToRooms < ActiveRecord::Migration[6.1]
  def change
    add_column(:rooms, :code, :string)
    add_column(:rooms, :shared_code, :string)
    add_column(:rooms, :use_shared_code, :boolean)

    add_index(:rooms, :code, unique: true)
  end
end
