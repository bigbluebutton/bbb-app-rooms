# frozen_string_literal: true

class WaitChannel < ApplicationCable::Channel
  def subscribed
    stream_from WaitChannel.full_channel_name(params)
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def self.full_channel_name(params)
    "wait:#{params[:room]}:#{params[:meeting]}"
  end
end
