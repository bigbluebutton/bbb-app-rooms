Rails.application.routes.draw do
  scope ENV['RELATIVE_URL_ROOT'] || '/' do

    namespace :api do
      namespace :v1 do
        get 'sso/launch/:token', to: 'sso#validate_launch', as: :sso_launch
        get 'users/:id', to: 'users#show', as: :users
        get 'user', to: 'users#show', as: :user
      end
    end

    use_doorkeeper do
      # Including 'skip_controllers :application' disables the controller for managing external applications
      #   [http://example.com/lti/oauth/applications]
      skip_controllers :applications unless ENV['DEVELOPER_MODE_ENABLED'] == 'true'
    end
    
    root to: 'application#index', app: ENV['DEFAULT_LTI_TOOL'] || 'default'

    # requests from tool consumer go through this path
    post ':app/messages/blti', to: 'message#basic_lti_launch_request', as: 'blti_launch'

    # requests from xml_config go through these paths
    post ':app/messages/content-item', to: 'message#content_item_selection', as: 'content_item_request_launch'
    post ':app/messages/content-item', to: 'message#basic_lti_launch_request', as: 'content_item_launch'

    post ':app/register', to: 'registration#register', as: :tool_registration
    post ':app/reregister', to: 'registration#register', as: :tool_update_registration
    post ':app/submit_capabilities', to: 'registration#save_capabilities', as: 'save_capabilities'
    get  ':app/submit_proxy/:registration_uuid', to: 'registration#submit_proxy', as: 'submit_proxy'

    # LTI LAUNCH URL (responds to get and post)
    get  ':app/launch', to: 'application#launch', as: :lti_apps
    # match 'launch' => 'application#launch', via: [:get, :post], as: :lti_launch

    get ':app/xml_config', to: 'tool_profile#xml_config', as: :xml_config, app: ENV['DEFAULT_LTI_TOOL'] || 'default'
    get ':app/xml_builder', to: 'tool_profile#xml_builder', app: ENV['DEFAULT_LTI_TOOL'] || 'default', as: :xml_builder if ENV['DEVELOPER_MODE_ENABLED'] == 'true'
    # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

    mount RailsLti2Provider::Engine => '/rails_lti2_provider'
  end
end
