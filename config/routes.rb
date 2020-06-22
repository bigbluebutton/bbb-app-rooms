Rails.application.routes.draw do
  scope ENV['RELATIVE_URL_ROOT'] || '' do
    scope 'rooms' do
      get '/close', :to => 'rooms#close', as: :autoclose

      # Handles recording management.
      scope ':id/recording/:record_id' do
        post '/publish', :to => 'rooms#recording_publish', as: :recording_publish
        post '/unpublish', :to => 'rooms#recording_unpublish', as: :recording_unpublish
        post '/protect', :to => 'rooms#recording_protect', as: :recording_protect
        post '/unprotect', :to => 'rooms#recording_unprotect', as: :recording_unprotect
        post '/update', :to => 'rooms#recording_update', as: :recording_update
        post '/delete', :to => 'rooms#recording_delete', as: :recording_delete
      end

      # Handles launches.
      #get 'launch', :to => 'sessions#new', as: :launch
      get 'launch', :to => 'rooms#launch', as: :room_launch

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

    # Handles meeting management.
    resources :rooms do
      resources :scheduled_meetings, only: [:new, :create, :edit, :update] do
        member do
          post :join
        end
      end
    end
  end
end
