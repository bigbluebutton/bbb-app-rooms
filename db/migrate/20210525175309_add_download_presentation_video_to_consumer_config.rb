class AddDownloadPresentationVideoToConsumerConfig < ActiveRecord::Migration[6.0]
  def change
    add_column(:consumer_configs, :download_presentation_video, :boolean, default: true)
  end
end
