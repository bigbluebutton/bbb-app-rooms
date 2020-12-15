# frozen_string_literal: true

# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/.
#
# Copyright (c) 2018 BigBlueButton Inc. and by respective authors (see below).
#
# This program is free software; you can redistribute it and/or modify it under the
# terms of the GNU Lesser General Public License as published by the Free Software
# Foundation; either version 3.0 of the License, or (at your option) any later
# version.
#
# BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License along
# with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.

require 'bigbluebutton_api'

module BbbServer
  extend ActiveSupport::Concern

  def bbb_server
    BigBlueButton::BigBlueButtonApi.new(Rails.configuration.bigbluebutton_endpoint, Rails.configuration.bigbluebutton_secret)
  end

  # Returns a list of all running meetings
  def all_meetings
    bbb_server.get_meetings
  end

  # Returns all the recordings of the server
  def all_recordings(room_handler = nil)
    begin
      if room_handler.empty?
        meeting_ids = all_meeting_ids
        res = bbb_server.get_recordings(meetingID: meeting_ids) unless meeting_ids.empty?
      else
        res = bbb_server.get_recordings(meetingID: room_handler)
      end

      res = res.nil? ? { recordings: {} } : res
      # Format playbacks in a more pleasant way.

      res[:recordings].each do |r|
        next if r.key?(:error)

        r[:playbacks] = if !r[:playback] || !r[:playback][:format]
                          []
                        elsif r[:playback][:format].is_a?(Array)
                          r[:playback][:format]
                        else
                          [r[:playback][:format]]
                        end

        r.delete(:playback)
      end

      recs = res[:recordings].sort_by { |rec| rec[:endTime] }.reverse
    rescue BigBlueButton::BigBlueButtonException
      logger.info('Error fetching recordings.')
      recs = []
    end

    recs
  end

  # Deletes a recording.
  def delete_server_recording(record_id)
    bbb_server.delete_recordings(record_id)
  end

  # Publishes a recording.
  def publish_server_recording(record_id)
    bbb_server.publish_recordings(record_id, true)
  end

  # Unpublishes a recording.
  def unpublish_server_recording(record_id)
    bbb_server.publish_recordings(record_id, false)
  end

  # Updates a recording.
  def update_server_recording(record_id, meta)
    meta[:recordID] = record_id
    bbb_server.send_api_request('updateRecordings', meta)
  end

  private

  def all_meeting_ids
    handlers = Room.limit(10).pluck(:handler) # only retrieve 10

    handlers.nil? ? [] : handlers
  end
end
