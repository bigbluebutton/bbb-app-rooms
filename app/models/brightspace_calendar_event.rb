class BrightspaceCalendarEvent < ApplicationRecord
  belongs_to :scheduled_meeting,
             primary_key: :hash_id,
             foreign_key: :scheduled_meeting_hash_id,
             inverse_of: :brightspace_calendar_event

  validates :scheduled_meeting_hash_id, presence: true, uniqueness: true
  validates :room_id, presence: true
  validates :event_id, presence: true, uniqueness: { scope: :room_id }
  validates :link_id, uniqueness: { scope: :room_id }
end
