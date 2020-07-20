# frozen_string_literal: true

FactoryBot.define do
  factory :room do
    name { Faker::Name.unique.name }
    description { Faker::Lorem.sentence }
    welcome { Faker::Lorem.sentence }
    moderator { Faker::Name.unique.name }
    viewer { Faker::Name.unique.name }
    recording { false }
    wait_moderator { false }
    all_moderators { false }
    created_at { Time.zone.local(2020) }
    updated_at { Time.zone.now }
    handler { 'handler' }
  end
end
