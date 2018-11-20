BbbLtiBroker::Application.routes.draw do

  scope ENV['RELATIVE_URL_ROOT'] || '/' do
    namespace :api do
      namespace :v1 do
        get 'sso/launches/:token', to: 'sso#validate_launch', as: :sso_launches
        get 'users/:id', to: 'users#show', as: :users
        get 'user', to: 'users#show', as: :user
      end
    end

    use_doorkeeper do
      skip_controllers :applications
    end

    post 'callback', to: 'collaboration_callbacks#confirm_url'
    delete 'callback', to: 'collaboration_callbacks#confirm_url'

    get ':app/guide', to: 'guide#home'

    root to: 'guide#home', :app => ENV["DEFAULT_TOOL"] || 'default'

    get ':app/xml_config', to: 'guide#xml_config', as: :xml_config
    get ':app/xml_builder', to: 'guide#xml_builder', as: :xml_builder

    resources :tool_proxy, only: [:create]

    post ':app/messages/blti', to: 'message#basic_lti_launch_request', as: 'blti_launch'
    post ':app/messages/content-item', to: 'message#content_item_selection', as: 'content_item_request_launch'
    post ':app/messages/content-item', to: 'message#basic_lti_launch_request', as: 'content_item_launch'
    post ':app/messages/signed_content_item_request', to: 'message#signed_content_item_request'

    post ':app/register', to: 'registration#register', as: :tool_registration
    post ':app/reregister', to: 'registration#register', as: :tool_reregistration
    post ':app/submit_capabilities', to: 'registration#save_capabilities', as: 'save_capabilities'
    get  ':app/submit_proxy/:registration_uuid', to: 'registration#submit_proxy', as: 'submit_proxy'

    get  ':app/launch', to: 'apps#index', as: :lti_apps

    mount RailsLti2Provider::Engine => "/rails_lti2_provider"
  end
end
