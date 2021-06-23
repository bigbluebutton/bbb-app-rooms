# frozen_string_literal: true

# This program is free software; you can redistribute it and/or modify it under the
# terms of the GNU Lesser General Public License as published by the Free Software
# Foundation; either version 3.0 of the License, or (at your option) any later
# version.

# BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

# You should have received a copy of the GNU Lesser General Public License along
# with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.

module AdminsHelper
  def active_page
    route = Rails.application.routes.recognize_path(request.env['PATH_INFO'])

    route[:action]
  end

  def room_configuration_string(name)
    case name
    when 'enabled'
      t('administrator.room_configuration.options.enabled')
    when 'optional'
      t('administrator.room_configuration.options.optional')
    when 'disabled'
      t('administrator.room_configuration.options.disabled')
    end
  end
end
