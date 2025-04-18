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

ActiveRecord::Schema[7.2].define(version: 2025_04_17_203310) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_stat_statements"
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "name", null: false
    t.string "currency", default: "MXN", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "platform", default: 0, null: false
    t.text "settings_ciphertext"
    t.index ["user_id"], name: "index_accounts_on_user_id"
  end

  create_table "balances", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "date", null: false
    t.integer "transfers_cents", default: 0, null: false
    t.integer "diff_cents"
    t.integer "diff_days"
    t.text "currency", default: "MXN", null: false
    t.boolean "validated", default: false
    t.index ["account_id"], name: "index_balances_on_account_id"
    t.index ["date", "account_id", "currency"], name: "one_currency_balance_per_day", unique: true
  end

  create_table "currency_rates", force: :cascade do |t|
    t.string "currency", null: false
    t.bigint "rate_subcents", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "date", null: false
    t.index ["date", "currency"], name: "index_currency_rates_on_date_and_currency", unique: true
  end

  create_table "passkeys", force: :cascade do |t|
    t.string "nickname"
    t.string "external_id"
    t.string "public_key"
    t.bigint "user_id", null: false
    t.bigint "sign_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_passkeys_on_external_id", unique: true
    t.index ["user_id"], name: "index_passkeys_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token_digest", null: false
    t.string "remember_digest"
    t.datetime "expires_at", precision: nil, null: false
    t.index ["remember_digest"], name: "index_sessions_on_remember_digest", unique: true, where: "(remember_digest IS NOT NULL)"
    t.index ["token_digest"], name: "index_sessions_on_token_digest", unique: true
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "uid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "settings"
    t.index ["email"], name: "index_users_on_email", unique: true, where: "(email IS NOT NULL)"
    t.index ["uid"], name: "index_users_on_uid", unique: true, where: "(uid IS NOT NULL)"
  end

  add_foreign_key "accounts", "users"
  add_foreign_key "balances", "accounts"
  add_foreign_key "passkeys", "users"
  add_foreign_key "sessions", "users"
end
