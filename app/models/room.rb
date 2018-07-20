class Room < ApplicationRecord
  before_save :default_values

  def default_values
    self.handler ||= Digest::SHA1.hexdigest(SecureRandom.uuid)
    self.moderator = random_password(8) if self.moderator.empty?
    self.viewer = random_password(8, self.moderator) if self.viewer.empty?
  end

  private

    def random_password(length, reference = '')
    o = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten
    begin
      password = (0...length).map { o[rand(o.length)] }.join
    end while password == reference
    password
  end

end
