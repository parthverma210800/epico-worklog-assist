class CreateLeaves < ActiveRecord::Migration[8.1]
  def change
    create_table :leaves do |t|
      t.references :user, null: false, foreign_key: true
      t.date :leave_date, null: false
      t.string :leave_type, null: false, default: "full_day"
      t.string :status, null: false, default: "approved"

      t.timestamps
    end
    add_index :leaves, %i[user_id leave_date]
  end
end
