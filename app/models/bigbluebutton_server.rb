class BigbluebuttonServer < ApplicationRecord
  belongs_to :brightspace_oauth

  validates :key, uniqueness: true

  def domain
    begin
      URI.parse(self.endpoint).host
    rescue URI::InvalidURIError
      nil
    end
  end
end
