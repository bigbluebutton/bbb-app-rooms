# frozen_string_literal: true

# Pre-set omniauth variables based on ENV
Rails.configuration.omniauth_site = ENV['OMNIAUTH_BBBLTIBROKER_SITE']
Rails.configuration.omniauth_root = "#{ENV['OMNIAUTH_BBBLTIBROKER_ROOT'] ? '/' + ENV['OMNIAUTH_BBBLTIBROKER_ROOT'] : ''}"
Rails.configuration.omniauth_key = ENV["OMNIAUTH_BBBLTIBROKER_KEY"]
Rails.configuration.omniauth_secret = ENV["OMNIAUTH_BBBLTIBROKER_SECRET"]

OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
  # Initialize the provider
  provider(
    :bbbltibroker,
    Rails.configuration.omniauth_key,
    Rails.configuration.omniauth_secret,
    {
      provider_ignores_state: true,
      path_prefix: "#{Rails.configuration.relative_url_root}/auth",
      omniauth_root: "#{Rails.configuration.omniauth_root}",
      # define the oauth endpoint for the authentication
      raw_info_url: "#{Rails.configuration.omniauth_root}/api/v1/session.json",
      scope: 'api',
      # define the parameters expected as part of the response along with [uid]
      info_params: [
        'userid',
        'lis_person_name_full',
        'roles',
        'resource_link_title',
        'resource_link_description'
      ],
      client_options: {
        site: Rails.configuration.omniauth_site,
        code: 'rooms',
        authorize_url: "#{Rails.configuration.omniauth_root}/oauth/authorize",
        token_url: "#{Rails.configuration.omniauth_root}/oauth/token",
        revoke_url: "#{Rails.configuration.omniauth_root}/oauth/revoke"
      }
    }
  ) unless Rails.configuration.omniauth_site.empty? || Rails.configuration.omniauth_key.empty? || Rails.configuration.omniauth_secret.empty? || false
end
