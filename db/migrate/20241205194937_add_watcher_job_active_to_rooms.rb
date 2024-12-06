# frozen_string_literal: true

class AddWatcherJobActiveToRooms < ActiveRecord::Migration[6.1]
  def up
    add_column(:rooms, :watcher_job_active, :boolean, default: false, null: false)
  end

  def down
    remove_column(:rooms, :watcher_job_active)
  end
end
