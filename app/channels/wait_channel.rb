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
class WaitChannel < ApplicationCable::Channel
  def subscribed
    @room = Room.find(params[:room_id])
    stream_for(@room)
  rescue ActiveRecord::RecordNotFound
    nil # To catch attempts to subscribe when wait for mod isn't required.
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def notify_join
    NotifyMeetingWatcherJob.perform_now(Room.find(params[:room_id]), action: 'joined from wait')
  end
end
