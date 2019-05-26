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

ActiveRecord::Schema.define(version: 2019_05_26_175128) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "name", null: false
    t.string "currency", default: "MXN", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "balance_dates", force: :cascade do |t|
    t.date "date", null: false
    t.index ["date"], name: "index_balance_dates_on_date", unique: true
  end

  create_table "balances", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "balance_date_id", null: false
    t.integer "amount_cents", null: false
    t.integer "original_amount_cents"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["account_id"], name: "index_balances_on_account_id"
    t.index ["balance_date_id"], name: "index_balances_on_balance_date_id"
  end

  create_table "currency_rates", force: :cascade do |t|
    t.bigint "balance_date_id", null: false
    t.string "currency", null: false
    t.bigint "rate_subcents", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["balance_date_id"], name: "index_currency_rates_on_balance_date_id"
  end

  create_table "totals", force: :cascade do |t|
    t.bigint "balance_date_id", null: false
    t.integer "amount_cents", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["balance_date_id"], name: "index_totals_on_balance_date_id"
  end

  add_foreign_key "balances", "accounts"
  add_foreign_key "balances", "balance_dates"
  add_foreign_key "currency_rates", "balance_dates"
  add_foreign_key "totals", "balance_dates"
end
