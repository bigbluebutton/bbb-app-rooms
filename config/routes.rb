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

Rails.application.routes.draw do
  get '/health_check', to: 'health_check#all'
  get '/healthz', to: 'health_check#all'
  root to: 'health_check#all'

  mount ActionCable.server => "#{ENV['RELATIVE_URL_ROOT'] ? '/' + ENV['RELATIVE_URL_ROOT'] : ''}/rooms/cable"

  scope ENV['RELATIVE_URL_ROOT'] || '' do
    scope 'rooms' do
      get '/health_check', to: 'health_check#all'
      get '/healthz', to: 'health_check#all'

      # Handles meeting management.
      scope ':id/meeting' do
        post '/join', to: 'rooms#meeting_join', as: :meeting_join
        get '/join', to: 'rooms#meeting_join'
        post '/end', to: 'rooms#meeting_end', as: :meeting_end
        get '/close', to: 'rooms#meeting_close', as: :autoclose
      end

      # Handles recording management.
      scope ':id/recording/:record_id' do
        post '/publish', to: 'rooms#recording_publish', as: :recording_publish
        post '/unpublish', to: 'rooms#recording_unpublish', as: :recording_unpublish
        post '/protect', to: 'rooms#recording_protect', as: :recording_protect
        post '/unprotect', to: 'rooms#recording_unprotect', as: :recording_unprotect
        post '/update', to: 'rooms#recording_update', as: :recording_update
        post '/delete', to: 'rooms#recording_delete', as: :recording_delete
      end

      # Handles launches.
      get 'launch', to: 'rooms#launch', as: :room_launch

      # Handles sessions.
      get '/sessions/create'
      get '/sessions/failure'

      # Handles Omniauth authentication.
      get '/auth/:provider', to: 'sessions#new', as: :omniauth_authorize
      get '/auth/:provider/callback', to: 'sessions#create', as: :omniauth_callback
      get '/auth/failure', to: 'sessions#failure', as: :omniauth_failure

      # Handles errors.
      get '/errors/:code', to: 'errors#index', as: :errors
    end

    resources :rooms
  end
end
