# frozen_string_literal: true

#
## BigBlueButton open source conferencing system - http://www.bigbluebutton.org/.
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
#

module ExtraParamsHelper
  extend ActiveSupport::Concern

  # return a hash of key:value pairs from the launch_params,
  # for keys that exist in the extra params hash retrieved from the broker settings
  def launch_and_extra_params_intersection_hash(launch_params, action, actions_hash)
    if Rails.configuration.cache_enabled
      Rails.cache.fetch("rooms/#{@chosen_room.handler}/tenant/#{@chosen_room.tenant}/user/#{@user.uid}/ext_#{action}_params",
                        expires_in: Rails.configuration.cache_expires_in_minutes.minutes) do
        calculate_intersection_hash(launch_params, actions_hash)
      end
    else
      calculate_intersection_hash(launch_params, actions_hash)
    end
  end

  def calculate_intersection_hash(launch_params, actions_hash)
    result = {}
    actions_hash&.each_key do |key|
      value = find_launch_param(launch_params, key)
      result[key] = value if value
    end
    result
  end

  # Check if the launch params contain a certain param
  # If they do, return the value of that param
  def find_launch_param(launch_params, key)
    return launch_params[key] if launch_params.key?(key)

    launch_params.each_value do |value|
      if value.is_a?(Hash)
        result = find_launch_param(value, key)
        return result if result
      end
    end

    nil
  end
end
