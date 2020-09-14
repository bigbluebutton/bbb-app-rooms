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

require 'user'
require 'bbb_api'
class NotifyMeetingWatcherJob < ApplicationJob
  include BbbApi
  include BbbAppRooms
  include ApplicationHelper

  queue_as :default

  def perform(room, data)
    @room = room
    data[:meeting_in_progress] = mod_in_room?
    if !data[:meeting_in_progress]
      data[:action] = 'end'
    else
      data[:elapsed_time] = meeting_start_time
      data[:participant_count] = participant_count
    end

    MeetingInfoChannel.broadcast_to(room, data)
  end
end
