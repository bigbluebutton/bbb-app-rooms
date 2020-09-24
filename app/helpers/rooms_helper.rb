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
module RoomsHelper
  def autoclose_url
    'javascript:window.close();'
  end

  def elapsed_time(start_time, curr_time)
    return 0 if start_time.nil?

    time = curr_time - start_time

    hrs = (time * 24).floor
    time -= hrs / 24.to_f

    mins = (time * 24 * 60).floor
    time -= mins / 1440.to_f

    secs = (time * 24 * 60 * 60).floor

    "#{add_zero_maybe(hrs)}:#{add_zero_maybe(mins)}:#{add_zero_maybe(secs)}"
  end

  def add_zero_maybe(num)
    num = '0' + num.to_s if num < 10

    num
  end
end
