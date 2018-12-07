require 'securerandom'
require 'bbb_lti_broker/helpers'

include BbbLtiBroker::Helpers

default_key = 'key'
default_secret = 'secret'

lti_config = YAML.load(File.read("#{Rails.root}/config/tool_providers.yml"))[Rails.env] || {}
lti_config.symbolize_keys!

unless RailsLti2Provider::Tool.find_by_uuid(default_key)
    RailsLti2Provider::Tool.create!(uuid: default_key, shared_secret: default_secret, lti_version: 'LTI-1p0', tool_settings:'none')
    lti_config[:tools].to_h.each do |key, props|
        next if key == 'default'
        Doorkeeper::Application.create!(
            :name => "#{key}",
            :uid => "#{props["uid"] || SecureRandom.hex(64)}",
            :secret => "#{props["secret"] || SecureRandom.hex(64)}",
            :redirect_uri => "#{props["site"] || 'http://localhost'}/apps/#{key}/auth/bbbltibroker/callback"
            )
    end
end
