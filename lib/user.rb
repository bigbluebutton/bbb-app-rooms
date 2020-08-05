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
module BbbAppRooms
  class User
    attr_accessor :uid, :full_name, :first_name, :last_name, :email, :roles, :locale

    def initialize(params)
      params.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
    end

    def moderator?(moderator_roles)
      moderator_roles = moderator_roles.split(',') unless moderator_roles.is_a?(Array)
      moderator_roles.any? do |role|
        role?(role)
      end
    end

    def admin?
      role?('Admin')
    end

    def role?(role)
      launch_roles.any? do |launch_role|
        launch_role.match(/#{role}/i)
      end
    end

    def username(default)
      return full_name if full_name
      return "#{first_name} #{last_name}" if first_name || last_name
      return email.split('@').first if email

      default
    end

    private

    def launch_roles
      return [] unless roles

      roles.split(',')
    end
  end
end
