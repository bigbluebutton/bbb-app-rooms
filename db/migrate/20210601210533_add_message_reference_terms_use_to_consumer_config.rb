class AddMessageReferenceTermsUseToConsumerConfig < ActiveRecord::Migration[6.0]
  def change
    add_column(:consumer_configs, :message_reference_terms_use, :boolean, default: true)
  end
end
