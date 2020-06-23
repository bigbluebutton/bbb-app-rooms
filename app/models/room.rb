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

  def api_attributes(scheduled_meeting = nil)
    id = api_meeting_id(scheduled_meeting)
    if scheduled_meeting.nil?
      name = self.name
    else
      name = scheduled_meeting.name
    end

    {
      meeting_id: id,
      name: name
    }
  end

  def ids_for_get_recordings
    scheduled_meetings.pluck(:created_at).map { |meeting|
      self.api_meeting_id(meeting)
    }.unshift(self.handler)
  end

  private

  def api_meeting_id(scheduled_meeting = nil)
    if scheduled_meeting.nil?
      self.handler
    elsif scheduled_meeting.is_a?(ScheduledMeeting)
      "#{self.handler}-#{scheduled_meeting.created_at.to_i}"
    elsif scheduled_meeting.is_a?(DateTime) || scheduled_meeting.is_a?(Time)
      "#{self.handler}-#{scheduled_meeting.to_i}"
    end
  end

  def random_password(length, reference = '')
    o = [('a'..'z'), ('A'..'Z'), ('0'..'9')].map { |i| i.to_a }.flatten
    begin
      password = (0...length).map { o[rand(o.length)] }.join
    end while password == reference
    password
  end
end
