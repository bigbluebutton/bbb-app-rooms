class SetKeyColumnsAsUnique < ActiveRecord::Migration[6.0]
  def change
    remove_index(:bigbluebutton_servers, :key)
    add_index(:bigbluebutton_servers, :key, unique: true)

    remove_index(:consumer_configs, :key)
    add_index(:consumer_configs, :key, unique: true)
  end
end
