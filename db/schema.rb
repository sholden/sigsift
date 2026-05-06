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

ActiveRecord::Schema[8.1].define(version: 2026_05_05_235857) do
  create_table "accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "lead_detections", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "potential_lead_id", null: false
    t.integer "scan_run_id", null: false
    t.index ["potential_lead_id"], name: "index_lead_detections_on_potential_lead_id"
    t.index ["scan_run_id"], name: "index_lead_detections_on_scan_run_id"
  end

  create_table "leads", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "client_name"
    t.string "contact_email"
    t.string "contact_name"
    t.string "contact_phone"
    t.datetime "created_at", null: false
    t.date "deadline"
    t.text "description"
    t.integer "estimated_budget_cents"
    t.text "notes"
    t.integer "opportunity_id", null: false
    t.integer "potential_lead_id"
    t.string "priority"
    t.string "status"
    t.string "time_horizon"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["opportunity_id"], name: "index_leads_on_opportunity_id"
    t.index ["potential_lead_id"], name: "index_leads_on_potential_lead_id"
  end

  create_table "opportunities", force: :cascade do |t|
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.text "criteria_structured"
    t.text "criteria_text"
    t.text "description"
    t.string "name", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_opportunities_on_account_id"
    t.index ["status"], name: "index_opportunities_on_status"
  end

  create_table "potential_leads", force: :cascade do |t|
    t.string "client_name"
    t.float "confidence_score"
    t.text "contact_info"
    t.datetime "created_at", null: false
    t.date "deadline_date"
    t.string "deadline_text"
    t.text "description"
    t.string "estimated_budget"
    t.string "fingerprint"
    t.integer "found_by_id", null: false
    t.string "location"
    t.text "raw_text"
    t.string "review_status"
    t.datetime "reviewed_at"
    t.integer "source_id", null: false
    t.string "source_url"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["found_by_id"], name: "index_potential_leads_on_found_by_id"
    t.index ["review_status"], name: "index_potential_leads_on_review_status"
    t.index ["source_id", "fingerprint"], name: "index_potential_leads_on_source_id_and_fingerprint"
    t.index ["source_id", "review_status"], name: "index_potential_leads_on_source_id_and_review_status"
    t.index ["source_id"], name: "index_potential_leads_on_source_id"
  end

  create_table "scan_run_traces", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "messages_json"
    t.text "metadata_json"
    t.integer "scan_run_id", null: false
    t.datetime "updated_at", null: false
    t.index ["scan_run_id"], name: "index_scan_run_traces_on_scan_run_id", unique: true
  end

  create_table "scan_runs", force: :cascade do |t|
    t.text "agent_context"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.text "error_message"
    t.string "job_id"
    t.integer "source_id", null: false
    t.datetime "started_at"
    t.string "status", default: "pending", null: false
    t.text "summary"
    t.integer "tool_calls_count", default: 0, null: false
    t.integer "total_cost_cents", default: 0, null: false
    t.integer "total_input_tokens", default: 0, null: false
    t.integer "total_output_tokens", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["source_id", "created_at"], name: "index_scan_runs_on_source_id_and_created_at"
    t.index ["source_id"], name: "index_scan_runs_on_source_id"
    t.index ["status"], name: "index_scan_runs_on_status"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "sources", force: :cascade do |t|
    t.integer "consecutive_failure_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "last_scanned_at"
    t.string "name", null: false
    t.text "notes"
    t.integer "opportunity_id", null: false
    t.integer "scan_frequency_days", default: 7, null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["last_scanned_at"], name: "index_sources_on_last_scanned_at"
    t.index ["opportunity_id"], name: "index_sources_on_opportunity_id"
    t.index ["status"], name: "index_sources_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_users_on_account_id"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "lead_detections", "potential_leads"
  add_foreign_key "lead_detections", "scan_runs"
  add_foreign_key "leads", "opportunities"
  add_foreign_key "leads", "potential_leads"
  add_foreign_key "opportunities", "accounts"
  add_foreign_key "potential_leads", "scan_runs", column: "found_by_id"
  add_foreign_key "potential_leads", "sources"
  add_foreign_key "scan_run_traces", "scan_runs"
  add_foreign_key "scan_runs", "sources"
  add_foreign_key "sessions", "users"
  add_foreign_key "sources", "opportunities"
  add_foreign_key "users", "accounts"
end
