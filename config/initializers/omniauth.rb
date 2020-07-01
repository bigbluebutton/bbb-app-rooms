# frozen_string_literal: true

# Pre-set omniauth variables based on ENV
Rails.configuration.omniauth_site = ENV['OMNIAUTH_BBBLTIBROKER_SITE']
Rails.configuration.omniauth_root = (
  ENV['OMNIAUTH_BBBLTIBROKER_ROOT'] ? '/' + ENV['OMNIAUTH_BBBLTIBROKER_ROOT'] : ''
).to_s
Rails.configuration.omniauth_key = ENV['OMNIAUTH_BBBLTIBROKER_KEY']
Rails.configuration.omniauth_secret = ENV['OMNIAUTH_BBBLTIBROKER_SECRET']

OmniAuth.config.logger = Rails.logger

missing_configs = Rails.configuration.omniauth_site.blank? ||
                  Rails.configuration.omniauth_key.blank? ||
                  Rails.configuration.omniauth_secret.blank?


OmniAuth.config.path_prefix = "#{Rails.configuration.relative_url_root}/auth"

module OmniAuth
  module Strategies
    class Bbbltibroker < OmniAuth::Strategies::OAuth2
      def callback_url
        # keep the launch nonce because we need it in case of errors
        full_host + script_name + callback_path +
          "?launch_nonce=#{request.params['launch_nonce']}"
      end
    end
  end
end

OmniAuth.config.on_failure = Proc.new do |env|
  request = Rack::Request.new(env)
  request.update_param(:provider, :bbbltiprovider)
  SessionsController.action(:failure).call(env)
end
# OmniAuth.config.failure_raise_out_environments = []

Rails.application.config.middleware.use(OmniAuth::Builder) do
  # provider :developer unless Rails.env.production?
  # Initialize the provider
  unless missing_configs
    provider(
      :bbbltibroker,
      Rails.configuration.omniauth_key,
      Rails.configuration.omniauth_secret,
      provider_ignores_state: true,
      path_prefix: "#{Rails.configuration.relative_url_root}/auth",
      omniauth_root: Rails.configuration.omniauth_root.to_s,
      raw_info_url: "#{Rails.configuration.omniauth_root}/api/v1/user.json",
      scope: 'api',
      info_params: %w[
        full_name
        first_name
        last_name
        email
      ],
      client_options: {
        site: Rails.configuration.omniauth_site.to_s,
        code: 'rooms',
        authorize_url: "#{Rails.configuration.omniauth_root}/oauth/authorize",
        token_url: "#{Rails.configuration.omniauth_root}/oauth/token",
        revoke_url: "#{Rails.configuration.omniauth_root}/oauth/revoke",
      }
    )
  end
end
