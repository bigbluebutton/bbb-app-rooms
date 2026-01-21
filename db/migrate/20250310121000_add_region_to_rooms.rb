# frozen_string_literal: true

class AddRegionToRooms < ActiveRecord::Migration[6.1]
  def change
    add_column(:rooms, :region, :string)
  end
end
