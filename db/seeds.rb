default_key = 'key'
default_secret = 'secret'

unless RailsLti2Provider::Tool.find_by_uuid(default_key)
    RailsLti2Provider::Tool.create!(uuid: default_key, shared_secret: default_secret, lti_version: 'LTI-1p0', tool_settings:'none')
    Doorkeeper::Application.create!(:name => "Rooms LTI", :uid => "b21211c29d2720a4c847fc3a9097720a196f7fafddbaa0f68d5c1cb54fdbb046", :secret => "3590e00d7ebd398b75c4ea5a65097a19a687d72715af811bc8b3e78aa1664789", :redirect_uri => 'https://localhost/apps/rooms/auth/bbbltibroker/callback')
else
    puts 'No need to seed'
end
