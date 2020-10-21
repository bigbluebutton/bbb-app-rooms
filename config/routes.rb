# frozen_string_literal: true

Rails.application.routes.draw do
  if Rails.configuration.cable_enabled
    mount ActionCable.server => Rails.configuration.action_cable.mount_path
  end

  scope ENV['RELATIVE_URL_ROOT'] || '' do
    scope 'rooms' do
      get '/health_check', to: 'health_check#all', default: { format: nil }
      get '/healthz', to: 'health_check#all', default: { format: nil }

      get '/close', to: 'rooms#close', as: :autoclose

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
      get '/launch', to: 'rooms#launch', as: :room_launch

      # Handles sessions.
      get '/sessions/create'
      get '/sessions/failure'

      # Handles Omniauth authentication.
      get '/auth/:provider', to: 'sessions#new', as: :omniauth_authorize
      get '/auth/:provider/callback', to: 'sessions#create', as: :omniauth_callback
      get '/auth/:provider/failure', to: 'sessions#failure', as: :omniauth_failure
      get '/auth/:provider/retry', to: 'sessions#retry', as: :omniauth_retry

      # Handles errors.
      get '/errors/:code', to: 'errors#index', as: :errors
    end

    # NOTE: there are other actions in the rooms controller, but they are not used for now,
    #       rooms are automatically created when needed and can't be edited
    resources :rooms, only: :show do
      member do
        get :recordings
      end

      resources :scheduled_meetings, only: [:new, :create, :edit, :update, :destroy] do
        member do
          post :join
          get :external
          get :wait
          get :send_create_calendar_event, to: 'brightspace#send_create_calendar_event'
          get :send_update_calendar_event, to: 'brightspace#send_update_calendar_event'
          get :send_delete_calendar_event, to: 'brightspace#send_delete_calendar_event'
        end
      end
    end
  end

  # To treat errors on pages that don't fall on any other controller
  match '*path' => 'application#on_404', via: :all
end
