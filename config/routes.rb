Rails.application.routes.draw do
  scope ENV['RELATIVE_URL_ROOT'] || '' do
    resources :rooms
    scope 'rooms/:id/meeting' do
      post '/join', :to => 'rooms#meeting_join', as: :meeting_join
      post '/end', :to => 'rooms#meeting_end', as: :meeting_end
      get '/close', :to => 'rooms#meeting_close', as: :autoclose
    end
    scope 'rooms/:id/recording' do
      post '/publish', :to => 'rooms#recording_publish', as: :recording_join
      post '/unpublish', :to => 'rooms#recording_unpublish', as: :recording_unpublish
      post '/protect', :to => 'rooms#recording_protect', as: :recording_protect
      post '/unprotect', :to => 'rooms#recording_unprotect', as: :recording_unprotect
      post '/update', :to => 'rooms#recording_update', as: :recording_update
      post '/delete', :to => 'rooms#recording_delete', as: :recording_delete
    end
    get '/launch', :to => 'rooms#launch', as: :launch
    get '/sessions/create'
    get '/sessions/failure'
    get '/auth/:provider/callback', to: 'sessions#create', as: :omniauth_callback
    get '/auth/failure', to: 'sessions#failure', as: :omniauth_failure
    get '/errors/:code', to: 'errors#index', as: :errors
  end
end
