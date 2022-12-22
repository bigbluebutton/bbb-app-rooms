# frozen_string_literal: true

class AddHideNameDescToRooms < ActiveRecord::Migration[6.1]
  def change
    add_column(:rooms, :hide_name, :boolean)
    add_column(:rooms, :hide_description, :boolean)
  end
end
