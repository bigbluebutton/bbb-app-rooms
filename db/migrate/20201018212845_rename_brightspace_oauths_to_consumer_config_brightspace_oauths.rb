class RenameBrightspaceOauthsToConsumerConfigBrightspaceOauths < ActiveRecord::Migration[6.0]
  def up
    # rename the old table and create the new reference
    rename_table(:brightspace_oauths, :consumer_config_brightspace_oauths)
    add_reference(:consumer_config_brightspace_oauths, :consumer_config, foreign_key: true)

    # update each brightspace oauth with the correct consumer_config_id
    sql = "UPDATE consumer_config_brightspace_oauths ccbo SET consumer_config_id = (" \
          "SELECT consumer_config_id FROM consumer_config_servers ccs " \
          "WHERE ccs.brightspace_oauth_id = ccbo.id LIMIT 1 " \
          ")"
    ActiveRecord::Base.connection.execute(sql)

    # remove the old key
    remove_column(:consumer_config_servers, :brightspace_oauth_id)
  end

  def down
    rename_table(:consumer_config_brightspace_oauths, :brightspace_oauths)
    add_column(:consumer_config_servers, :brightspace_oauth_id, :bigint)
    add_index(:consumer_config_servers, :brightspace_oauth_id,
              name: "index_consumer_config_servers_on_brightspace_oauth_id")
    add_foreign_key(:consumer_config_servers, :brightspace_oauths)

    sql = "UPDATE consumer_config_servers ccs SET brightspace_oauth_id = (" \
          "SELECT id FROM brightspace_oauths bo " \
          "WHERE ccs.consumer_config_id = bo.consumer_config_id LIMIT 1 " \
          ")"
    ActiveRecord::Base.connection.execute(sql)

    remove_reference(:brightspace_oauths, :consumer_config)
  end
end
