class AddSetDurationToConsumerConfigs < ActiveRecord::Migration[6.0]
  def change
    add_column(:consumer_configs, :set_duration, :boolean, default: false)
  end
end
