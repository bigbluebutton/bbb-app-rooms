class ScheduledMeeting < ApplicationRecord
  belongs_to :room

  def to_param
    self.id.to_s
  end

  def self.from_param(param)
    find_by(id: param)
  end

  def meeting_id
    "#{room.handler}-#{self.created_at.to_i}"
  end
end
