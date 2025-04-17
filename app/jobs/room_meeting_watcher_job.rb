# frozen_string_literal: true

class RoomMeetingWatcherJob < ApplicationJob
  queue_as :default
  include BbbHelper

  def perform(room, data)
    return unless room

    @chosen_room = room

    info = fetch_meeting_info(data)
    if info[:meeting_in_progress]
      @chosen_room.update(watcher_job_active: true) unless @chosen_room.watcher_job_active # no need to update if it's already true

      logger.info("Meeting in progress. Sending broadcast to room '#{room.name}'")
      # Broadcast updates to this room’s channel
      MeetingInfoChannel.broadcast_to(room, info)

      # Re-enqueue to run again in 5 seconds
      self.class.set(wait: 10.seconds).perform_later(room, info)
    else
      logger.info("Meeting is not in progress. Sending broadcast to room '#{room.name}'")

      # Broadcast that the meeting ended
      MeetingInfoChannel.broadcast_to(room, { meeting_in_progress: false, action: 'end' })
      @chosen_room.update(watcher_job_active: false) if @chosen_room.watcher_job_active # no need to update if it's already false
      # Do not re-enqueue, job ends here
    end
  end

  private

  def fetch_meeting_info(data)
    info = meeting_info
    data[:meeting_in_progress] = (info[:returncode] == 'SUCCESS' || info[:running] == true)
    # Data for meeting not in progress.
    (data[:action] = 'end') && (return data) unless data[:meeting_in_progress]

    # Data for meeting in progress.
    data[:elapsed_time] = info[:startTime]
    data[:participant_count] = info[:participantCount]
    data
  end
end
