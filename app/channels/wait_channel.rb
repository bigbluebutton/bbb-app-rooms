class WaitChannel < ApplicationCable::Channel
  def subscribed
    # stream_from "some_channel"
    puts "--------------------------------- some user is subscribed ----------------------------------"
    stream_from "room_#{params[:room]}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
