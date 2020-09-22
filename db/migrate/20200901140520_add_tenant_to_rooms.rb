# frozen_string_literal: true

class AddTenantToRooms < ActiveRecord::Migration[6.0]
  def self.up
    add_column(:rooms, :tenant, :string)
    add_index(:rooms, [:tenant, :handler], unique: true)
    remove_index(:rooms, :handler)
  end

  def self.down
    remove_index(:rooms, column: [:tenant, :handler])
    remove_column(:rooms, :tenant)
  end
end
