# frozen_string_literal: true

Rails.application.routes.draw do
  mount ActionCable.server => "#{ENV['RELATIVE_URL_ROOT'] ? '/' + ENV['RELATIVE_URL_ROOT'] : ''}/rooms/cable"

  scope ENV['RELATIVE_URL_ROOT'] || '' do
    scope 'rooms' do
      
      get '/health_check', to: 'health_check#all'
      get '/healthz', to: 'health_check#all'

      # Handles meeting management.
      scope ':id/meeting' do
        post '/join', to: 'rooms#meeting_join', as: :meeting_join
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
