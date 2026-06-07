class CreateIntegrationConnections < ActiveRecord::Migration[8.1]
  def change
    create_table :integration_connections do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.text :access_token
      t.string :scopes
      t.string :status, null: false, default: "connected"
      t.datetime :connected_at

      t.timestamps
    end
    add_index :integration_connections, %i[user_id provider], unique: true
  end
end
