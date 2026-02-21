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

ActiveRecord::Schema[8.0].define(version: 2026_02_21_214044) do
  create_table "accounts", force: :cascade do |t|
    t.string "name", null: false
    t.integer "account_type", null: false
    t.string "institution_name"
    t.decimal "balance", precision: 12, scale: 2, default: "0.0"
    t.decimal "interest_rate", precision: 5, scale: 4
    t.decimal "minimum_payment", precision: 10, scale: 2
    t.decimal "credit_limit", precision: 12, scale: 2
    t.decimal "original_balance", precision: 12, scale: 2
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "budget_categories", force: :cascade do |t|
    t.string "name", null: false
    t.integer "position", null: false
    t.string "icon"
    t.string "color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_budget_categories_on_name", unique: true
  end

  create_table "budget_items", force: :cascade do |t|
    t.integer "budget_period_id", null: false
    t.integer "budget_category_id", null: false
    t.string "name", null: false
    t.decimal "planned_amount", precision: 12, scale: 2, default: "0.0"
    t.decimal "spent_amount", precision: 12, scale: 2, default: "0.0"
    t.boolean "rollover", default: false
    t.decimal "fund_goal", precision: 12, scale: 2, default: "0.0"
    t.decimal "fund_balance", precision: 12, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["budget_category_id"], name: "index_budget_items_on_budget_category_id"
    t.index ["budget_period_id"], name: "index_budget_items_on_budget_period_id"
  end

  create_table "budget_periods", force: :cascade do |t|
    t.integer "year", null: false
    t.integer "month", null: false
    t.integer "status", default: 0
    t.decimal "total_income", precision: 12, scale: 2, default: "0.0"
    t.decimal "total_planned", precision: 12, scale: 2, default: "0.0"
    t.decimal "total_spent", precision: 12, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["year", "month"], name: "index_budget_periods_on_year_and_month", unique: true
  end

  create_table "csv_imports", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "file_name"
    t.integer "status", default: 0
    t.json "column_mapping"
    t.integer "records_imported", default: 0
    t.integer "records_skipped", default: 0
    t.text "error_log"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_csv_imports_on_account_id"
  end

  create_table "debt_payments", force: :cascade do |t|
    t.integer "account_id", null: false
    t.integer "budget_period_id"
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.date "payment_date", null: false
    t.decimal "principal_portion", precision: 12, scale: 2
    t.decimal "interest_portion", precision: 12, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_debt_payments_on_account_id"
    t.index ["budget_period_id"], name: "index_debt_payments_on_budget_period_id"
  end

  create_table "forecasts", force: :cascade do |t|
    t.string "name", null: false
    t.json "assumptions"
    t.integer "projection_months", null: false
    t.json "results"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "incomes", force: :cascade do |t|
    t.integer "budget_period_id", null: false
    t.string "source_name", null: false
    t.decimal "expected_amount", precision: 12, scale: 2
    t.decimal "received_amount", precision: 12, scale: 2
    t.date "pay_date"
    t.boolean "recurring", default: false
    t.integer "frequency"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["budget_period_id"], name: "index_incomes_on_budget_period_id"
  end

  create_table "net_worth_snapshots", force: :cascade do |t|
    t.date "recorded_at", null: false
    t.decimal "total_assets", precision: 12, scale: 2
    t.decimal "total_liabilities", precision: 12, scale: 2
    t.decimal "net_worth", precision: 12, scale: 2, null: false
    t.json "breakdown"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recorded_at"], name: "index_net_worth_snapshots_on_recorded_at", unique: true
  end

  create_table "recurring_bills", force: :cascade do |t|
    t.string "name", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.integer "account_id"
    t.integer "budget_category_id"
    t.integer "due_day", null: false
    t.integer "frequency"
    t.boolean "auto_create_transaction", default: false
    t.integer "reminder_days_before"
    t.boolean "active", default: true
    t.date "last_paid_date"
    t.date "next_due_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "start_date"
    t.integer "custom_interval_value"
    t.integer "custom_interval_unit"
    t.index ["account_id"], name: "index_recurring_bills_on_account_id"
    t.index ["budget_category_id"], name: "index_recurring_bills_on_budget_category_id"
  end

  create_table "savings_goals", force: :cascade do |t|
    t.string "name", null: false
    t.decimal "target_amount", precision: 12, scale: 2, null: false
    t.decimal "current_amount", precision: 12, scale: 2, default: "0.0"
    t.date "target_date"
    t.integer "category"
    t.integer "priority"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "transaction_splits", force: :cascade do |t|
    t.integer "transaction_record_id", null: false
    t.integer "budget_item_id", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["budget_item_id"], name: "index_transaction_splits_on_budget_item_id"
    t.index ["transaction_record_id"], name: "index_transaction_splits_on_transaction_record_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.integer "account_id"
    t.integer "budget_item_id"
    t.date "date", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.string "description"
    t.string "merchant"
    t.text "notes"
    t.integer "transaction_type", null: false
    t.boolean "imported", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_transactions_on_account_id"
    t.index ["budget_item_id"], name: "index_transactions_on_budget_item_id"
    t.index ["date"], name: "index_transactions_on_date"
    t.index ["transaction_type"], name: "index_transactions_on_transaction_type"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "budget_items", "budget_categories"
  add_foreign_key "budget_items", "budget_periods"
  add_foreign_key "csv_imports", "accounts"
  add_foreign_key "debt_payments", "accounts"
  add_foreign_key "debt_payments", "budget_periods"
  add_foreign_key "incomes", "budget_periods"
  add_foreign_key "recurring_bills", "accounts"
  add_foreign_key "recurring_bills", "budget_categories"
  add_foreign_key "sessions", "users"
  add_foreign_key "transaction_splits", "budget_items"
  add_foreign_key "transaction_splits", "transactions", column: "transaction_record_id"
  add_foreign_key "transactions", "accounts"
  add_foreign_key "transactions", "budget_items"
end
