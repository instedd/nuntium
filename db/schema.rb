# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20091203201252) do

  create_table "ao_messages", :force => true do |t|
    t.string   "from"
    t.string   "to"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "guid"
    t.datetime "timestamp"
    t.integer  "application_id"
    t.integer  "tries",          :default => 0,         :null => false
    t.string   "subject"
    t.string   "state",          :default => "pending", :null => false
  end

  add_index "ao_messages", ["guid"], :name => "index_ao_messages_on_guid"

  create_table "application_logs", :force => true do |t|
    t.integer  "application_id"
    t.integer  "channel_id"
    t.integer  "ao_message_id"
    t.integer  "at_message_id"
    t.text     "message"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "severity"
  end

  create_table "applications", :force => true do |t|
    t.string   "name"
    t.string   "password"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "salt"
    t.integer  "max_tries",     :default => 3,     :null => false
    t.string   "interface",     :default => "rss"
    t.string   "configuration"
  end

  create_table "at_messages", :force => true do |t|
    t.string   "from"
    t.string   "to"
    t.text     "body"
    t.string   "guid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "timestamp"
    t.integer  "application_id"
    t.integer  "tries",          :default => 0,         :null => false
    t.string   "subject"
    t.string   "state",          :default => "pending", :null => false
  end

  create_table "channels", :force => true do |t|
    t.string   "name"
    t.string   "kind"
    t.integer  "application_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "configuration"
    t.string   "protocol"
    t.integer  "direction"
  end

  create_table "cron_tasks", :force => true do |t|
    t.integer  "interval"
    t.datetime "next_run"
    t.datetime "last_run"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "parent_id"
    t.string   "parent_type", :limit => 60
    t.string   "code"
    t.string   "name"
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "qst_outgoing_messages", :force => true do |t|
    t.string   "guid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "channel_id"
  end

  add_index "qst_outgoing_messages", ["guid"], :name => "index_unread_ao_messages_on_guid"

  create_table "twitter_channel_statuses", :force => true do |t|
    t.integer  "channel_id"
    t.integer  "last_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
