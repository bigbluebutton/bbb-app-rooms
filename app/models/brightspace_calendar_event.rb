class BrightspaceCalendarEvent < ApplicationRecord
  belongs_to :scheduled_meeting

  validates :scheduled_meeting, presence: true, uniqueness: true
  validates :room_id, presence: true
  validates :event_id, presence: true, uniqueness: { scope: :room_id }
  validates :link_id, uniqueness: { scope: :room_id }
end
