class CreateBigbluebuttonServers < ActiveRecord::Migration[6.0]
  def change
    create_table :bigbluebutton_servers do |t|
      t.string(:key, unique: true)
      t.string(:endpoint)
      t.string(:secret)
      t.string(:internal_endpoint)
    end

    add_index(:bigbluebutton_servers, :key)
  end
end
