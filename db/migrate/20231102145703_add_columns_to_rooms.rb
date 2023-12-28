# frozen_string_literal: true

class AddColumnsToRooms < ActiveRecord::Migration[6.1]
  def change
    change_table(:rooms, bulk: true) do |t|
      t.string(:code)
      t.string(:shared_code)
      t.boolean(:use_shared_code)
    end

    add_index(:rooms, :code, unique: true)
  end
end
