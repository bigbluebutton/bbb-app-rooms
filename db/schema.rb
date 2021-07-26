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


ActiveRecord::Schema.define(version: 2021_07_14_174949) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "app_launches", force: :cascade do |t|
    t.string "nonce"
    t.jsonb "params"
    t.datetime "expires_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.jsonb "omniauth_auth"
    t.string "room_handler"
    t.index ["expires_at"], name: "index_app_launches_on_expires_at"
    t.index ["nonce"], name: "index_app_launches_on_nonce"
    t.index ["room_handler"], name: "index_app_launches_on_room_handler"
  end

  create_table "brightspace_calendar_events", force: :cascade do |t|
    t.integer "event_id"
    t.string "scheduled_meeting_hash_id"
    t.bigint "room_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "link_id"
    t.index ["event_id", "room_id"], name: "index_brightspace_calendar_events_on_event_id_and_room_id", unique: true
    t.index ["link_id", "room_id"], name: "index_brightspace_calendar_events_on_link_id_and_room_id", unique: true
    t.index ["room_id"], name: "index_brightspace_calendar_events_on_room_id"
    t.index ["scheduled_meeting_hash_id"], name: "index_brightspace_calendar_events_on_scheduled_meeting_hash_id"
  end

  create_table "consumer_config_brightspace_oauths", force: :cascade do |t|
    t.string "url"
    t.string "client_id"
    t.string "client_secret"
    t.string "scope"
    t.bigint "consumer_config_id"
    t.index ["consumer_config_id"], name: "index_consumer_config_brightspace_oauths_on_consumer_config_id"
    t.index ["url"], name: "index_consumer_config_brightspace_oauths_on_url"
  end

  create_table "consumer_config_servers", force: :cascade do |t|
    t.string "endpoint"
    t.string "secret"
    t.string "internal_endpoint"
    t.bigint "consumer_config_id"
    t.index ["consumer_config_id"], name: "index_consumer_config_servers_on_consumer_config_id"
  end

  create_table "consumer_configs", force: :cascade do |t|
    t.string "key"
    t.string "external_disclaimer"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "set_duration", default: false
    t.boolean "message_reference_terms_use", default: true
    t.boolean "download_presentation_video", default: true
    t.index ["key"], name: "index_consumer_configs_on_key", unique: true
  end

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
    t.boolean "allow_wait_moderator", default: true
    t.boolean "allow_all_moderators", default: true
    t.string "consumer_key"
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
    t.string "description"
    t.string "welcome"
    t.string "created_by_launch_nonce"
    t.string "repeat"
    t.boolean "disable_external_link", default: false
    t.boolean "disable_private_chat", default: false
    t.boolean "disable_note", default: false
    t.string "hash_id"
    t.index ["created_by_launch_nonce"], name: "index_scheduled_meetings_on_created_by_launch_nonce"
    t.index ["hash_id"], name: "index_scheduled_meetings_on_hash_id", unique: true
    t.index ["repeat"], name: "index_scheduled_meetings_on_repeat"
    t.index ["room_id"], name: "index_scheduled_meetings_on_room_id"
  end

  add_foreign_key "brightspace_calendar_events", "rooms"
  add_foreign_key "consumer_config_brightspace_oauths", "consumer_configs"
  add_foreign_key "consumer_config_servers", "consumer_configs"
end
