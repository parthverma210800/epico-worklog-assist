class CreateProjectAllocations < ActiveRecord::Migration[8.1]
  def change
    create_table :project_allocations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.integer :daily_hours, null: false, default: 8
      t.boolean :active, null: false, default: true

      t.timestamps
    end
    add_index :project_allocations, %i[user_id project_id], unique: true
  end
end
