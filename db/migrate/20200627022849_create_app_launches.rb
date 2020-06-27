class CreateAppLaunches < ActiveRecord::Migration[6.0]
  def change
    create_table :app_launches do |t|
      t.string(:nonce)
      t.jsonb(:params)
      t.datetime(:expires_at)

      t.timestamps
    end

    add_index(:app_launches, :nonce)
  end
end
