class NotifyRoomWatcherJob < ApplicationJob
  queue_as :default

  def perform(room)
    room.broadcast_room_start
  end
end
