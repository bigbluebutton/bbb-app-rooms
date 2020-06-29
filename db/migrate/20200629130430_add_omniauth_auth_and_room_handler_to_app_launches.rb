class AddOmniauthAuthAndRoomHandlerToAppLaunches < ActiveRecord::Migration[6.0]
  def change
    add_column(:app_launches, :omniauth_auth, :jsonb)
    add_column(:app_launches, :room_handler, :string)
  end
end
