class WaitForModeratorToGuestPolicyInRoomSettings < ActiveRecord::Migration[6.1]
  def change
    Room.find_each do |room|
      room.wait_moderator = (room.settings['waitForModerator'] == '1')
      room.settings['guestPolicy'] = '1' if room.settings['waitForModerator'] == '1'
      room.save!
    end
  end
end
