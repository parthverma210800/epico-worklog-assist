# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_06_08_193439) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "integration_connections", force: :cascade do |t|
    t.text "access_token"
    t.datetime "connected_at"
    t.datetime "created_at", null: false
    t.string "provider", null: false
    t.string "scopes"
    t.string "status", default: "connected", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "provider"], name: "index_integration_connections_on_user_id_and_provider", unique: true
    t.index ["user_id"], name: "index_integration_connections_on_user_id"
  end

  create_table "project_allocations", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.integer "daily_hours", default: 8, null: false
    t.date "end_date"
    t.bigint "project_id", null: false
    t.date "start_date"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["project_id"], name: "index_project_allocations_on_project_id"
    t.index ["user_id", "project_id"], name: "index_project_allocations_on_user_id_and_project_id", unique: true
    t.index ["user_id"], name: "index_project_allocations_on_user_id"
  end

  create_table "project_repositories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "project_id", null: false
    t.string "provider", default: "github", null: false
    t.string "repo_full_name", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_project_repositories_on_project_id"
    t.index ["provider", "repo_full_name"], name: "index_project_repositories_on_provider_and_repo_full_name", unique: true
  end

  create_table "projects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.date "end_date"
    t.string "name"
    t.string "project_type"
    t.date "start_date"
    t.string "status"
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.bigint "epico_user_id"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["epico_user_id"], name: "index_users_on_epico_user_id", unique: true
  end

  create_table "worklog_drafts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.decimal "hours", precision: 4, scale: 2, default: "0.0", null: false
    t.string "origin", default: "deterministic", null: false
    t.bigint "project_id", null: false
    t.jsonb "source_refs", default: [], null: false
    t.string "status", default: "suggested", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.date "work_date", null: false
    t.index ["project_id"], name: "index_worklog_drafts_on_project_id"
    t.index ["user_id", "project_id", "work_date", "status"], name: "idx_on_user_id_project_id_work_date_status_345b2e02a2"
    t.index ["user_id", "work_date"], name: "index_worklog_drafts_on_user_id_and_work_date"
    t.index ["user_id"], name: "index_worklog_drafts_on_user_id"
  end

  create_table "worklogs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.decimal "hours", precision: 4, scale: 2, default: "0.0", null: false
    t.bigint "project_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.date "work_date", null: false
    t.index ["project_id"], name: "index_worklogs_on_project_id"
    t.index ["user_id", "project_id", "work_date"], name: "index_worklogs_on_user_id_and_project_id_and_work_date"
    t.index ["user_id", "work_date"], name: "index_worklogs_on_user_id_and_work_date"
    t.index ["user_id"], name: "index_worklogs_on_user_id"
  end

  add_foreign_key "integration_connections", "users"
  add_foreign_key "project_allocations", "projects"
  add_foreign_key "project_allocations", "users"
  add_foreign_key "project_repositories", "projects"
  add_foreign_key "worklog_drafts", "projects"
  add_foreign_key "worklog_drafts", "users"
  add_foreign_key "worklogs", "projects"
  add_foreign_key "worklogs", "users"
end
