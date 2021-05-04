class MigrateBigbluebuttonServersToConsumerConfigsServers < ActiveRecord::Migration[6.0]
  def up
    # rename the old table and create the new reference
    rename_table(:bigbluebutton_servers, :consumer_config_servers)
    add_reference(:consumer_config_servers, :consumer_config, foreign_key: true)

    # for each server, look for a consumer config with the same key
    sql = "SELECT * FROM consumer_config_servers"
    servers = ActiveRecord::Base.connection.execute(sql)
    servers.each do |s|
      sql = "SELECT id FROM consumer_configs WHERE key = '#{s['key']}'"
      config = ActiveRecord::Base.connection.execute(sql)

      # if there's no consumer config yet create one
      if config.to_a.empty?
        sql = "INSERT INTO consumer_configs (key,created_at,updated_at) " \
              "VALUES ('#{s['key']}', NOW(), NOW()) " \
              "RETURNING id"
        inserted = ActiveRecord::Base.connection.execute(sql)
      end
    end

    # associate the consumer config with the server
    sql = "UPDATE consumer_config_servers ccs SET consumer_config_id = (" \
          "SELECT cc.id FROM consumer_configs cc WHERE cc.key = ccs.key" \
          ")"
    ActiveRecord::Base.connection.execute(sql)

    # remove the old key
    remove_column(:consumer_config_servers, :key)
  end

  def down
    rename_table(:consumer_config_servers, :bigbluebutton_servers)
    add_column(:bigbluebutton_servers, :key, :string, unique: true)
    add_index(:bigbluebutton_servers, :key)

    sql = "UPDATE bigbluebutton_servers SET key = (" \
          "SELECT key FROM consumer_configs WHERE id = consumer_config_id" \
          ")"
    ActiveRecord::Base.connection.execute(sql)

    remove_reference(:bigbluebutton_servers, :consumer_config)
  end
end
