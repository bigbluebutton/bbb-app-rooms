class Room < ApplicationRecord
  before_save :default_values

  has_many :scheduled_meetings

  attr_accessor :can_grade

  def to_param
    self.handler
  end

  def self.from_param(param)
    find_by(handler: param)
  end

  def default_values
    self.handler ||= Digest::SHA1.hexdigest(SecureRandom.uuid)
    self.moderator = random_password(8) if moderator.blank?
    self.viewer = random_password(8, moderator) if viewer.blank?
  end

  def ids_for_get_recordings
    scheduled_meetings.map { |meeting| meeting.meeting_id }
  end

  private

  def random_password(length, reference = '')
    o = [('a'..'z'), ('A'..'Z'), ('0'..'9')].map(&:to_a).flatten
    password = ''
    loop do
      password = (0...length).map { o[rand(o.length)] }.join
      break unless password == reference
    end
    password
  end
end
