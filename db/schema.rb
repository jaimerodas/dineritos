# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_12_30_181324) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "name", null: false
    t.string "currency", default: "MXN", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "user_id", null: false
    t.integer "account_type", default: 0, null: false
    t.text "settings_ciphertext"
    t.integer "last_balance_cents"
    t.datetime "last_balance_updated_at"
    t.index ["user_id"], name: "index_accounts_on_user_id"
  end

  create_table "balance_dates", force: :cascade do |t|
    t.date "date", null: false
    t.bigint "user_id", null: false
    t.index ["date"], name: "index_balance_dates_on_date", unique: true
    t.index ["user_id"], name: "index_balance_dates_on_user_id"
  end

  create_table "balances", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.integer "amount_cents", null: false
    t.integer "original_amount_cents"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.date "date", null: false
    t.integer "transfers_cents", default: 0, null: false
    t.integer "diff_cents"
    t.integer "diff_days"
    t.index ["account_id"], name: "index_balances_on_account_id"
    t.index ["date", "account_id"], name: "index_balances_on_date_and_account_id", unique: true
  end

  create_table "currency_rates", force: :cascade do |t|
    t.string "currency", null: false
    t.bigint "rate_subcents", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.date "date", null: false
    t.index ["date", "currency"], name: "index_currency_rates_on_date_and_currency", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token_digest", null: false
    t.string "remember_digest"
    t.datetime "expires_at", null: false
    t.index ["remember_digest"], name: "index_sessions_on_remember_digest", unique: true, where: "(remember_digest IS NOT NULL)"
    t.index ["token_digest"], name: "index_sessions_on_token_digest", unique: true
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "totals", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.date "date", null: false
    t.bigint "user_id"
    t.index ["date"], name: "index_totals_on_date", unique: true
    t.index ["user_id"], name: "index_totals_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "uid"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.jsonb "settings"
    t.index ["email"], name: "index_users_on_email", unique: true, where: "(email IS NOT NULL)"
    t.index ["uid"], name: "index_users_on_uid", unique: true, where: "(uid IS NOT NULL)"
  end

  add_foreign_key "accounts", "users"
  add_foreign_key "balance_dates", "users"
  add_foreign_key "balances", "accounts"
  add_foreign_key "sessions", "users"
  add_foreign_key "totals", "users"
end
