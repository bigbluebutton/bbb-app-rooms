class AddBrightspaceOauthRefToBigbluebuttonServers < ActiveRecord::Migration[6.0]
  def change
    add_reference :bigbluebutton_servers, :brightspace_oauth, foreign_key: true
  end
end
