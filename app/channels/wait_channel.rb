# frozen_string_literal: true

class WaitChannel < ApplicationCable::Channel
  def subscribed
    stream_from("wait_channel:room_#{params[:room]}")
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
