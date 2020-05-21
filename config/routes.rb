# frozen_string_literal: true

Rails.application.routes.draw do
  scope ENV['RELATIVE_URL_ROOT'] || '/' do
    # rooms calls this api to validate launch from broker
    namespace :api do
      namespace :v1 do
        get 'sso/launch/:token', to: 'sso#validate_launch', as: :sso_launch
        get 'users/:id', to: 'users#show', as: :users
        get 'user', to: 'users#show', as: :user
      end
    end

    # grades
    get 'grades/:grades_token/list', to: 'grades#grades_list', as: :grades_list
    post 'grades/:grades_token/change', to: 'grades#send_grades', as: :send_grades

    # registration (LMS -> broker)
    get 'registration/list', to: 'registration#list', as: :registration_list
    get 'registration/new', to: 'registration#new', as: :new_registration if ENV['DEVELOPER_MODE_ENABLED'] == 'true'
    get 'registration/edit', to: 'registration#edit', as: :edit_registration
    post 'registration/submit', to: 'registration#submit', as: :submit_registration
    get 'registration/delete', to: 'registration#delete', as: :delete_registration

    # registration (broker -> rooms)
    use_doorkeeper do
      # Including 'skip_controllers :application' disables the controller for managing external applications
      #   [http://example.com/lti/oauth/applications]
      skip_controllers :applications unless ENV['DEVELOPER_MODE_ENABLED'] == 'true'
    end

    root to: 'application#index', app: ENV['DEFAULT_LTI_TOOL'] || 'default'

    # lti 1.3 authenticate user through login
    post ':app/auth/login', to: 'auth#login', as: 'openid_login'
    post ':app/messages/oblti', to: 'message#openid_launch_request', as: 'openid_launch'
    # requests from tool consumer go through this path
    post ':app/messages/blti', to: 'message#basic_lti_launch_request', as: 'blti_launch'

    # requests from xml_config go through these paths
    post ':app/messages/content-item', to: 'message#content_item_selection', as: 'content_item_request_launch'
    post ':app/messages/content-item', to: 'message#basic_lti_launch_request', as: 'content_item_launch'
    post ':app/messages/deep-link', to: 'message#deep_link', as: 'deep_link_request_launch'
    post ':app/messages/signed_content_item_request', to: 'message#signed_content_item_request'

    # LTI LAUNCH URL (responds to get and post)
    get  ':app/launch', to: 'application#launch', as: :lti_apps
    # match 'launch' => 'application#launch', via: [:get, :post], as: :lti_launch

    match ':app/json_config/:temp_key_token', to: 'tool_profile#json_config', via: [:get, :post], as: 'json_config' # , :defaults => {:format => 'json'}

    # xml config and builder for lti 1.0/1.1
    get ':app/xml_config', to: 'tool_profile#xml_config', as: :xml_config, app: ENV['DEFAULT_LTI_TOOL'] || 'default'
    get ':app/xml_builder', to: 'tool_profile#xml_builder', app: ENV['DEFAULT_LTI_TOOL'] || 'default', as: :xml_builder if ENV['DEVELOPER_MODE_ENABLED'] == 'true'
    # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

    mount RailsLti2Provider::Engine => '/rails_lti2_provider'
  end
end
