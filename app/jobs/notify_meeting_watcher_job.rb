# frozen_string_literal: true

#  BigBlueButton open source conferencing system - http://www.bigbluebutton.org/.
#
#  Copyright (c) 2018 BigBlueButton Inc. and by respective authors (see below).
#
#  This program is free software; you can redistribute it and/or modify it under the
#  terms of the GNU Lesser General Public License as published by the Free Software
#  Foundation; either version 3.0 of the License, or (at your option) any later
#  version.
#
#  BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
#  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
#  PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public License along
#  with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.

require 'bbb_app_rooms/user'

class NotifyMeetingWatcherJob < ApplicationJob
  # Include libraries.
  include BbbAppRooms
  # Include concerns.
  include BbbHelper
  include OmniauthHelper

  queue_as :default

  def perform(room, data)
    @room = room
    MeetingInfoChannel.broadcast_to(room, job_data(data))
  end

  private

  def job_data(data)
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
