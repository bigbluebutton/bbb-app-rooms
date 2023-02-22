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

class SessionsController < ApplicationController
  # Include concerns.
  include OmniauthHelper

  before_action :print_parameters if Rails.configuration.developer_mode_enabled

  def new; end

  def create
    omniauth_auth = request.env['omniauth.auth']
    omniauth_params = request.env['omniauth.params']

    # Return error if authentication fails
    redirect_post(omniauth_failure_path, options: { authenticity_token: :auto }) && return unless omniauth_auth&.uid

    # As authentication did not fail, initialize the session
    session[omniauth_params['launch_nonce']] = omniauth_auth.to_hash.slice('uid')
    redirect_post(room_launch_url(launch_nonce: omniauth_params['launch_nonce']), options: { authenticity_token: :auto })
  end

  def failure
    redirect_to(errors_url(500))
  end
end
