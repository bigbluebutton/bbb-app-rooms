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

    def wait_for_mod?
      return unless @room && @user

      @room.wait_moderator && !@user.moderator?(bigbluebutton_moderator_roles)
    end

    def mod_in_room?
      bbb.is_meeting_running?(@room.handler)
    end

    def meeting_info
      bbb.get_meeting_info(@room.handler, @user)
    end

    def participant_count
      return false unless mod_in_room?

      meeting_info[:participantCount]
    end

    def meeting_start_time
      return nil unless mod_in_room?

      meeting_info[:startTime]
    end

    def end_meeting
      return bbb.end_meeting(@room.handler, meeting_info[:moderatorPW]) if mod_in_room?

      mod_in_room?
    end

    def join_meeting_url
      return unless @room && @user

      unless bbb
        @error = {
          key: t('error.bigbluebutton.invalidrequest.code'),
          message: t('error.bigbluebutton.invalidrequest.message'),
          suggestion: t('error.bigbluebutton.invalidrequest.suggestion'),
          status: :internal_server_error,
        }
        return
      end
      bbb.create_meeting(@room.name, @room.handler,
                         moderatorPW: @room.moderator,
                         attendeePW: @room.viewer,
                         welcome: @room.welcome,
                         record: @room.recording,
                         logoutURL: autoclose_url,
                         "meta_description": @room.description)
      role = @user.moderator?(bigbluebutton_moderator_roles) || @room.all_moderators ? 'moderator' : 'viewer'
      bbb.join_meeting_url(@room.handler, @user.username(t("default.bigbluebutton.#{role}")), @room.attributes[role])
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
  end
end
