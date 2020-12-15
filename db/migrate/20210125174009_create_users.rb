# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[6.0]
  def change
    create_table(:users) do |t|
      t.string(:context)
      t.string(:uid)
      t.string(:full_name)
      t.string(:first_name)
      t.string(:last_name)
      t.datetime(:last_accessed_at)
      t.string(:username)
      t.string(:password_digest)
      t.boolean(:admin)
      t.timestamps(null: false)
    end

    add_index(:users, :id)
    add_index(:users, [:context, :uid])
    add_index(:users, :username, unique: true)
  end
end
