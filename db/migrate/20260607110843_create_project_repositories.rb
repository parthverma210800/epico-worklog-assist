class CreateProjectRepositories < ActiveRecord::Migration[8.1]
  def change
    create_table :project_repositories do |t|
      t.references :project, null: false, foreign_key: true
      t.string :provider, null: false, default: "github"
      t.string :repo_full_name, null: false

      t.timestamps
    end
    add_index :project_repositories, %i[provider repo_full_name], unique: true
  end
end
