class Room < ApplicationRecord
  before_save :default_values

  has_many :scheduled_meetings
  has_many :app_launches, primary_key: :handler, foreign_key: :room_handler

  attr_accessor :can_grade

  def last_launch
    app_launches.order('created_at DESC').first
  end

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

  def params_for_get_recordings
    { meetingID: self.meeting_id, meetingIDWildcard: true }
  end

  def meeting_id
    "#{self.handler}-#{self.id}"
  end

  def attributes_for_meeting
    {
      recording: self.recording,
      all_moderators: self.all_moderators,
      wait_moderator: self.wait_moderator
    }
  end

  def update_recurring_meetings
    self.scheduled_meetings.inactive.recurring.find_each do |meeting|
      meeting.update_to_next_recurring_date
    end
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
