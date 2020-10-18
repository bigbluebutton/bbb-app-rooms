class ConsumerConfig < ApplicationRecord
  validates :key, uniqueness: true

  has_one :server,
          class_name: "ConsumerConfigServer",
          foreign_key: :consumer_config_id
end
