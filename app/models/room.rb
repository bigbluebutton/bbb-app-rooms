# frozen_string_literal: true

class Room < ApplicationRecord
  before_save :default_values

  attr_accessor :can_grade

  def default_values
    self.handler ||= Digest::SHA1.hexdigest(SecureRandom.uuid)
    self.moderator = random_password(8) if moderator.blank?
    self.viewer = random_password(8, moderator) if viewer.blank?
  end

  def broadcast_room_start
    ActionCable.server.broadcast("room_#{id}", action: 'started')
  end

  private

  def random_password(length, reference = '')
    o = [('a'..'z'), ('A'..'Z'), ('0'..'9')].map(&:to_a).flatten
    loop do
      password = (0...length).map { o[rand(o.length)] }.join
      break unless password == reference
    end
    password
  end
end
