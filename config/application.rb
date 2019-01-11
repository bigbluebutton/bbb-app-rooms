require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module BbbAppRooms
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    config.action_dispatch.default_headers.delete "X-Frame-Options"

    config.autoload_paths << Rails.root.join("lib")
    config.eager_load_paths << Rails.root.join("lib")

    config.omniauth_bbbltibroker_key = ENV["OMNIAUTH_BBBLTIBROKER_KEY"] || "key"
    config.omniauth_bbbltibroker_secret = ENV["OMNIAUTH_BBBLTIBROKER_SECRET"] || "secret"

    # Check if a loadbalancer is configured.
    config.loadbalancer_configured = ENV["LOADBALANCER_ENDPOINT"].present? && ENV["LOADBALANCER_SECRET"].present?

    # Setup BigBlueButton configuration.
    if config.loadbalancer_configured
      # Fetch credentials from a loadbalancer based on provider.
      config.loadbalancer_endpoint = ENV["LOADBALANCER_ENDPOINT"]
      config.loadbalancer_secret = ENV["LOADBALANCER_SECRET"]
    else
      # Default credentials (test-install.blindsidenetworks.com/bigbluebutton).
      config.bigbluebutton_endpoint_default = "http://test-install.blindsidenetworks.com/bigbluebutton/api/"
      config.bigbluebutton_secret_default = "8cd8ef52e8e101574e400365b55e11a6"
      config.bigbluebutton_moderator_roles_default = "Instructor,Faculty,Teacher,Mentor,Administrator,Admin"

      # Use standalone BigBlueButton server.
      config.bigbluebutton_endpoint = ENV["BIGBLUEBUTTON_ENDPOINT"] || config.bigbluebutton_endpoint_default
      config.bigbluebutton_secret = ENV["BIGBLUEBUTTON_SECRET"] || config.bigbluebutton_secret_default
      config.bigbluebutton_moderator_roles = ENV["BIGBLUEBUTTON_MODERATOR_ROLES"] || config.bigbluebutton_moderator_roles_default

      # Fix endpoint format if required.
      config.bigbluebutton_endpoint += "api/" unless config.bigbluebutton_endpoint.ends_with?('api/')
    end
  end
end
