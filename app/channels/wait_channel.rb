class WaitChannel < ApplicationCable::Channel
  def subscribed
    stream_from "wait_channel:room_#{params[:room]}:meeting_#{params[:meeting_id]}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
