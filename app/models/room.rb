class Room < ApplicationRecord
  before_save :default_values

  has_many :scheduled_meetings

  attr_accessor :can_grade

  def default_values
    self.handler ||= Digest::SHA1.hexdigest(SecureRandom.uuid)
    self.moderator = random_password(8) if self.moderator.blank?
    self.viewer = random_password(8, self.moderator) if self.viewer.blank?
  end

  def broadcast_room_start
    ActionCable.server.broadcast("room_#{self.id}", action: "started")
  end

  private

  def random_password(length, reference = '')
    o = [('a'..'z'), ('A'..'Z'), ('0'..'9')].map { |i| i.to_a }.flatten
    begin
      password = (0...length).map { o[rand(o.length)] }.join
    end while password == reference
    password
  end

end
