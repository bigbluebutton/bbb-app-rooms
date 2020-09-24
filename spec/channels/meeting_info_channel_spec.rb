# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(MeetingInfoChannel, type: :channel) do
  it 'subscribes to a stream when room id is provided' do
    @room = create(:room)
    subscribe(room_id: @room.id)

    expect(subscription).to(be_confirmed)
  end
end
