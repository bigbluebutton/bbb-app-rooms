# frozen_string_literal: true

class WaitChannel < ApplicationCable::Channel
  def subscribed
    # stream_from "some_channel"
    stream_from("room_#{params[:room]}")
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
