# frozen_string_literal: true

class CreateUsedCodes < ActiveRecord::Migration[6.1]
  def up
    create_table(:used_codes) do |t|
      t.string(:code, null: false)
      t.timestamps
    end
    add_index(:used_codes, :code, unique: true)
  end

  def down
    drop_table(:used_codes)
  end
end
