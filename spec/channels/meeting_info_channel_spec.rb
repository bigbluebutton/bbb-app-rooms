# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(MeetingInfoChannel, type: :channel) do
  it 'subscribes to a stream when room handler is provided' do
    @room = create(:room)
    subscribe(room_handler: @room.handler)

    expect(subscription).to(be_confirmed)
  end
end
