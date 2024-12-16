# frozen_string_literal: true

class AddIndexToTenantAndCode < ActiveRecord::Migration[6.1]
  def change
    add_index(:rooms, [:tenant, :code], unique: true)
  end
end
