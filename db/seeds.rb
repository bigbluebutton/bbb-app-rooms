# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

default_key = 'key'
default_secret = 'secret'

default_tools = [
    {
      :name => 'rooms',
      :uid => 'b21211c29d2720a4c847fc3a9097720a196f7fafddbaa0f68d5c1cb54fdbb046',
      :secret => '3590e00d7ebd398b75c4ea5a65097a19a687d72715af811bc8b3e78aa1664789',
      :redirect_uri => 'http://example.com/apps/rooms/auth/bbbltibroker/callback'
    }
]

unless RailsLti2Provider::Tool.find_by_uuid(default_key)
    RailsLti2Provider::Tool.create!(uuid: default_key, shared_secret: default_secret, lti_version: 'LTI-1p0', tool_settings:'none')
    default_tools.each do | tool |
      Doorkeeper::Application.create!(tool)
    end
end
