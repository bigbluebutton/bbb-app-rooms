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

ActiveRecord::Schema.define(version: 2020_06_23_183830) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "rooms", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.string "welcome"
    t.string "moderator"
    t.string "viewer"
    t.boolean "recording", default: true
    t.boolean "wait_moderator", default: true
    t.boolean "all_moderators", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "handler"
    t.index ["handler"], name: "index_rooms_on_handler"
  end

  create_table "scheduled_meetings", force: :cascade do |t|
    t.bigint "room_id"
    t.string "name", null: false
    t.datetime "start_at", null: false
    t.integer "duration", null: false
    t.boolean "recording", default: true
    t.boolean "wait_moderator", default: true
    t.boolean "all_moderators", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["room_id"], name: "index_scheduled_meetings_on_room_id"
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
