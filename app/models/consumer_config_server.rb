class ConsumerConfigServer < ApplicationRecord
  belongs_to :consumer_config

  def domain
    begin
      URI.parse(self.endpoint).host
    rescue URI::InvalidURIError
      nil
    end
  end
end
