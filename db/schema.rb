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

ActiveRecord::Schema[7.1].define(version: 2024_08_28_120625) do
  create_table "channels", force: :cascade do |t|
    t.string "title"
    t.string "src"
    t.text "description"
    t.datetime "last_build_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "url"
  end

  create_table "items", force: :cascade do |t|
    t.string "title"
    t.string "url"
    t.text "description"
    t.datetime "pub_date"
    t.string "guid"
    t.boolean "unread"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "channel_id", null: false
    t.boolean "disabled", default: false, null: false
    t.index ["channel_id"], name: "index_items_on_channel_id"
  end

  add_foreign_key "items", "channels"
end
