# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20130724030000) do

  create_table "directed_user_to_user_edges", force: true do |t|
    t.integer "owner_user_id"
    t.integer "friend_user_id"
  end

  add_index "directed_user_to_user_edges", ["friend_user_id"], name: "index_directed_user_to_user_edges_on_friend_user_id"
  add_index "directed_user_to_user_edges", ["owner_user_id"], name: "index_directed_user_to_user_edges_on_owner_user_id"

  create_table "photos", force: true do |t|
    t.integer  "owner_user_id"
    t.string   "owner_display_name"
    t.string   "owner_profile_url"
    t.string   "owner_profile_photo"
    t.integer  "theme_id"
    t.string   "theme_display_name"
    t.date     "created"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
  end

  add_index "photos", ["owner_user_id"], name: "index_photos_on_owner_user_id"
  add_index "photos", ["theme_display_name"], name: "index_photos_on_theme_display_name"
  add_index "photos", ["theme_id"], name: "index_photos_on_theme_id"

  create_table "sessions", force: true do |t|
    t.string   "session_id", null: false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at"

  create_table "themes", force: true do |t|
    t.string  "display_name"
    t.date    "created"
    t.date    "start"
    t.integer "preview_photo_id"
  end

  add_index "themes", ["created"], name: "index_themes_on_created"
  add_index "themes", ["start"], name: "index_themes_on_start"

  create_table "users", force: true do |t|
    t.string  "email"
    t.string  "google_user_id"
    t.string  "google_display_name"
    t.string  "google_public_profile_url"
    t.string  "google_public_profile_photo_url"
    t.string  "google_access_token"
    t.string  "google_refresh_token"
    t.integer "google_expires_in"
    t.integer "google_expires_at",               limit: 8
  end

  add_index "users", ["email"], name: "index_users_on_email"
  add_index "users", ["google_access_token"], name: "index_users_on_google_access_token"
  add_index "users", ["google_display_name"], name: "index_users_on_google_display_name"
  add_index "users", ["google_user_id"], name: "index_users_on_google_user_id"

  create_table "votes", force: true do |t|
    t.integer "owner_user_id"
    t.integer "photo_id"
  end

  add_index "votes", ["owner_user_id"], name: "index_votes_on_owner_user_id"
  add_index "votes", ["photo_id"], name: "index_votes_on_photo_id"

end
