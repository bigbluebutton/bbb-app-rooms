# frozen_string_literal: true

# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/.

# Copyright (c) 2018 BigBlueButton Inc. and by respective authors (see below).

# This program is free software; you can redistribute it and/or modify it under the
# terms of the GNU Lesser General Public License as published by the Free Software
# Foundation; either version 3.0 of the License, or (at your option) any later
# version.

# BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

# You should have received a copy of the GNU Lesser General Public License along
# with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.

require 'bbb/api'
require 'bbb/helper'

module BbbHelper
  extend ActiveSupport::Concern
  include Bbb::Api
  include Bbb::Helper

  # Deletes a recording from a room.
  def delete_recording(record_id)
    bbb.delete_recordings(record_id)
  end

  # Publishes a recording for a room.
  def publish_recording(record_id)
    bbb.publish_recordings(record_id, true)
  end

  # Unpublishes a recording for a room.
  def unpublish_recording(record_id)
    bbb.publish_recordings(record_id, false)
  end

  # Update recording for a room.
  def update_recording(record_id, meta)
    meta[:recordID] = record_id
    bbb.send_api_request('updateRecordings', meta)
  end
end
