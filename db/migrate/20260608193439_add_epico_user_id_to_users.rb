class AddEpicoUserIdToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :epico_user_id, :bigint
    add_index :users, :epico_user_id, unique: true
  end
end
