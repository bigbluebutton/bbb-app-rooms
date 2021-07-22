class AddIndexOnAppLaunchesExpiresAt < ActiveRecord::Migration[6.0]
  def change
    add_index(:app_launches, :expires_at)
  end
end
