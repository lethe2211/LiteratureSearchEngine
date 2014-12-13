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

ActiveRecord::Schema.define(version: 20141213043124) do

  create_table "accesses", force: true do |t|
    t.integer  "session_id"
    t.string   "access_type"
    t.integer  "rank"
    t.integer  "literature_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "accesses", ["literature_id"], name: "index_accesses_on_literature_id"
  add_index "accesses", ["session_id"], name: "index_accesses_on_session_id"

  create_table "articles", force: true do |t|
    t.string   "title"
    t.string   "url"
    t.integer  "cluster_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "events", force: true do |t|
    t.integer  "task_id"
    t.string   "event_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "events", ["task_id"], name: "index_events_on_task_id"

  create_table "literatures", force: true do |t|
    t.string   "title"
    t.string   "authors"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "logs", force: true do |t|
    t.string   "userid"
    t.string   "interfaceid"
    t.text     "query"
    t.integer  "rank"
    t.string   "relevance"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "relevances", force: true do |t|
    t.integer  "session_id"
    t.integer  "rank"
    t.string   "relevance"
    t.integer  "literature_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "relevances", ["literature_id"], name: "index_relevances_on_literature_id"
  add_index "relevances", ["session_id"], name: "index_relevances_on_session_id"

  create_table "sessions", force: true do |t|
    t.integer  "task_id"
    t.string   "query"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["task_id"], name: "index_sessions_on_task_id"

  create_table "tasks", force: true do |t|
    t.string   "userid"
    t.string   "interfaceid"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
