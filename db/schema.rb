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

ActiveRecord::Schema.define(version: 20150401190456) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "evernote_accounts", force: :cascade do |t|
    t.integer "user_id"
    t.string  "token"
    t.string  "shard"
    t.integer "token_expiration", limit: 8
    t.integer "update_count",               default: 0
  end

  add_index "evernote_accounts", ["user_id"], name: "index_evernote_accounts_on_user_id", unique: true, using: :btree

  create_table "recipes", force: :cascade do |t|
    t.string  "title"
    t.string  "guid"
    t.integer "update_sequence_num"
    t.integer "largest_resource_size"
    t.integer "evernote_account_id",   null: false
  end

  add_index "recipes", ["guid"], name: "index_recipes_on_guid", using: :btree

  add_foreign_key "recipes", "evernote_accounts"
end
