class ScheduledMeeting < ApplicationRecord
  belongs_to :room

  def self.from_param(param)
    ScheduledMeeting.find_by(id: param)
  end
end
