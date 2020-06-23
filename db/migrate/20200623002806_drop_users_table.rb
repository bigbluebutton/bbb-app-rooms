# frozen_string_literal: true

class DropUsersTable < ActiveRecord::Migration[6.0]
  def change
    drop_table :users do |t|
      t.string(:name)
    end
  end
end
