class CreateBrightspaceOauths < ActiveRecord::Migration[6.0]
  def change
    create_table :brightspace_oauths do |t|
      t.string :url, index: true
      t.string :client_id
      t.string :client_secret
      t.string :scope
    end
  end
end
