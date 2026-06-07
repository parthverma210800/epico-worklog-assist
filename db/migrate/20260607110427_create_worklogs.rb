class CreateWorklogs < ActiveRecord::Migration[8.1]
  def change
    create_table :worklogs do |t|
      t.references :user, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.date :work_date, null: false
      t.text :description, null: false
      t.decimal :hours, precision: 4, scale: 2, null: false, default: 0

      t.timestamps
    end
    add_index :worklogs, %i[user_id work_date]
    add_index :worklogs, %i[user_id project_id work_date]
  end
end
