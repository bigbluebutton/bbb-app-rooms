class CreateConsumerConfigs < ActiveRecord::Migration[6.0]
  def change
    create_table :consumer_configs do |t|
      t.string(:key)
      t.string(:external_disclaimer)
      t.timestamps
    end
    add_index(:consumer_configs, :key)
  end
end
