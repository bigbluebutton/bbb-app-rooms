# frozen_string_literal: true

class AddHideNameDescToRooms < ActiveRecord::Migration[6.1]
  def change
    change_table(:rooms, bulk: true) do |t|
      t.boolean(:hide_name)
      t.boolean(:hide_description)
    end
  end
end
