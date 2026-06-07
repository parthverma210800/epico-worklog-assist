class CreateWorklogDrafts < ActiveRecord::Migration[8.1]
  def change
    create_table :worklog_drafts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.date :work_date, null: false
      t.text :description
      t.decimal :hours, precision: 4, scale: 2, null: false, default: 0
      t.jsonb :source_refs, null: false, default: []
      t.string :origin, null: false, default: "deterministic"
      t.string :status, null: false, default: "suggested"

      t.timestamps
    end
    add_index :worklog_drafts, %i[user_id work_date]
    add_index :worklog_drafts, %i[user_id project_id work_date status]
  end
end
