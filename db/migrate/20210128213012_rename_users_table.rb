# frozen_string_literal: true

class RenameUsersTable < ActiveRecord::Migration[6.0]
  def change
    rename_table(:users, :adminpg_users)
  end
end
