# frozen_string_literal: true

class AddSettingsToRooms < ActiveRecord::Migration[6.1]
  def change
    add_column(:rooms, :settings, :jsonb, null: false, default: {})
  end
end
