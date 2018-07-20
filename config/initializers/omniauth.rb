Rails.application.config.middleware.use OmniAuth::Builder do
  # Pre-set omniauth variables based on ENV
  omniauth_path_prefix = "#{ENV['RELATIVE_URL_ROOT'] ? '/' + ENV['RELATIVE_URL_ROOT'] : ''}/auth"
  omniauth_site =ENV['OMNIAUTH_BBBLTIBROKER_SITE'] || "http://localhost:3000"
  omniauth_root = "#{ENV['OMNIAUTH_BBBLTIBROKER_ROOT'] ? '/' + ENV['OMNIAUTH_BBBLTIBROKER_ROOT'] : ''}"
  omniauth_key = ENV["OMNIAUTH_BBBLTIBROKER_KEY"] || ''
  omniauth_secret = ENV["OMNIAUTH_BBBLTIBROKER_SECRET"] || ''

  # Prepare the actual settings
  client_options = {
    site: omniauth_site || '',
    authorize_url: "#{omniauth_root || ''}/oauth/authorize",
    token_url: "#{omniauth_root || ''}/oauth/token",
    revoke_url: "#{omniauth_root || ''}/oauth/revoke"
  }
  options = { provider_ignores_state: true, path_prefix: omniauth_path_prefix, omniauth_root: omniauth_root, client_options: client_options }

  # Initialize the provider
  provider :bbbltibroker, omniauth_key, omniauth_secret, options unless omniauth_key.empty? and omniauth_secret.empty?
end
