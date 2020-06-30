class BigbluebuttonServer < ApplicationRecord
  validates :key, uniqueness: true

  def domain
    begin
      URI.parse(self.endpoint).host
    rescue URI::InvalidURIError
      nil
    end
  end
end
