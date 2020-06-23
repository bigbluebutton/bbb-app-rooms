class NotifyRoomWatcherJob < ApplicationJob
  queue_as :default

  def perform(scheduled_meeting)
    scheduled_meeting.broadcast_conference_started
  end
end
