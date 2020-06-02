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

ActiveRecord::Schema.define(version: 2020_05_28_195723) do

  create_table "rooms", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.string "welcome"
    t.string "moderator"
    t.string "viewer"
    t.boolean "recording"
    t.boolean "wait_moderator"
    t.boolean "all_moderators"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "handler"
    t.index ["handler"], name: "index_rooms_on_handler"
  end

  create_table "users", force: :cascade do |t|
    t.string "uid"
    t.string "roles"
    t.string "full_name"
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

end
