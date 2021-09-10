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

ActiveRecord::Schema.define(version: 2021_09_10_144443) do

  create_table "application_record_logs", force: :cascade do |t|
    t.string "owner_type", null: false
    t.integer "owner_id", null: false
    t.integer "user_id"
    t.integer "action", null: false
    t.text "data"
    t.string "message", limit: 1225
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["owner_id"], name: "index_application_record_logs_on_owner_id"
    t.index ["owner_type"], name: "index_application_record_logs_on_owner_type"
    t.index ["user_id"], name: "index_application_record_logs_on_user_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.string "title"
    t.text "body"
    t.integer "price"
    t.text "data"
    t.date "date"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  add_foreign_key "application_record_logs", "users"
end
