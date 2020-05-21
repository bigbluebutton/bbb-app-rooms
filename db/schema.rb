# frozen_string_literal: true

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

ActiveRecord::Schema.define(version: 2019_10_30_180012) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "oauth_access_grants", force: :cascade do |t|
    t.integer "resource_owner_id", null: false
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "scopes"
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.integer "resource_owner_id"
    t.bigint "application_id"
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.string "scopes"
    t.string "previous_refresh_token", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "rails_lti2_provider_lti_launches", id: :serial, force: :cascade do |t|
    t.bigint "tool_id"
    t.string "nonce"
    t.text "message"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "rails_lti2_provider_registrations", id: :serial, force: :cascade do |t|
    t.string "uuid"
    t.text "registration_request_params"
    t.text "tool_proxy_json"
    t.string "workflow_state"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint "tool_id"
    t.text "correlation_id"
    t.index ["correlation_id"], name: "index_rails_lti2_provider_registrations_on_correlation_id", unique: true
  end

  create_table "rails_lti2_provider_tools", id: :serial, force: :cascade do |t|
    t.string "uuid"
    t.text "shared_secret"
    t.text "tool_settings"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "lti_version"
  end

  create_table "users", force: :cascade do |t|
    t.string "context"
    t.string "uid"
    t.string "full_name"
    t.string "first_name"
    t.string "last_name"
    t.datetime "last_accessed_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["context", "uid"], name: "index_users_on_context_and_uid"
    t.index ["id"], name: "index_users_on_id"
  end

  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
end
