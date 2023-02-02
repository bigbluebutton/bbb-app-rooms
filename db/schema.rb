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

ActiveRecord::Schema.define(version: 2023_01_27_154216) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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
    t.string "tenant"
    t.boolean "hide_name"
    t.boolean "hide_description"
    t.jsonb "settings", default: {}, null: false
    t.index ["tenant", "handler"], name: "index_rooms_on_tenant_and_handler", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

end
