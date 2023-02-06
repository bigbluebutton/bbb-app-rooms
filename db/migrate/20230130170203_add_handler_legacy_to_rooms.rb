# frozen_string_literal: true

class AddHandlerLegacyToRooms < ActiveRecord::Migration[6.1]
  def change
    add_column(:rooms, :handler_legacy, :string)
    add_index(:rooms, [:tenant, :handler_legacy], unique: true)
  end
end
