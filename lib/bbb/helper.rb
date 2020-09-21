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

module Bbb
  module Helper
    def bigbluebutton_moderator_roles
      Rails.configuration.bigbluebutton_moderator_roles.split(',')
    end

    # Fetches all recordings for a room.
    def recordings
      res = bbb.get_recordings(meetingID: @room.handler)

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

      res[:recordings].sort_by { |rec| rec[:endTime] }.reverse
    end

    # Helper for converting BigBlueButton dates into the desired format.
    def recording_date(date)
      # note: if we really wanted ordinalization, then we can add an if statement to ordinalize if locale is en.
      # .ordinalize does not work with other locales
      return date.strftime("%B #{date.day}, %Y.") unless I18n.locale.eql?(:en)

      date.strftime("%B #{date.day.ordinalize}, %Y.")
    end

    # Helper for converting BigBlueButton dates into a nice length string.
    def recording_length(playbacks)
      # Stats format currently doesn't support length.
      valid_playbacks = playbacks.reject { |p| p[:type] == 'statistics' }
      return '0 min' if valid_playbacks.empty?

      len = valid_playbacks.first[:length]
      if len > 60
        "#{(len / 60).round} hrs"
      elsif len.zero?
        '< 1 min'
      else
        "#{len} min"
      end
    end

    # Removes trailing forward slash from a URL.
    def remove_slash(str)
      str.nil? ? nil : str.chomp('/')
    end
  end
end
