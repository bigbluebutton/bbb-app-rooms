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

ActiveRecord::Schema.define(version: 2021_01_28_213012) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "adminpg_users", force: :cascade do |t|
    t.string "context"
    t.string "uid"
    t.string "full_name"
    t.string "first_name"
    t.string "last_name"
    t.datetime "last_accessed_at"
    t.string "username"
    t.string "password_digest"
    t.boolean "admin"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["context", "uid"], name: "index_adminpg_users_on_context_and_uid"
    t.index ["id"], name: "index_adminpg_users_on_id"
    t.index ["username"], name: "index_adminpg_users_on_username", unique: true
  end

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
