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

ActiveRecord::Schema.define(:version => 20100426160000) do

  create_table "account_logs", :force => true do |t|
    t.integer  "account_id"
    t.integer  "channel_id"
    t.integer  "ao_message_id"
    t.integer  "at_message_id"
    t.text     "message"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "severity"
  end

  create_table "accounts", :force => true do |t|
    t.string   "name"
    t.string   "password"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "salt"
    t.integer  "max_tries",  :default => 3, :null => false
  end

  create_table "address_sources", :force => true do |t|
    t.integer  "account_id"
    t.string   "address"
    t.integer  "channel_id"
    t.datetime "timestamp"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "application_id"
  end

  add_index "address_sources", ["account_id", "address"], :name => "index_address_sources_on_application_id_and_address", :unique => true

  create_table "ao_messages", :force => true do |t|
    t.string   "from"
    t.string   "to"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "guid"
    t.datetime "timestamp"
    t.integer  "account_id"
    t.integer  "tries",               :default => 0,         :null => false
    t.string   "subject"
    t.string   "state",               :default => "pending", :null => false
    t.string   "channel_relative_id"
    t.integer  "channel_id"
    t.text     "custom_attributes"
    t.integer  "application_id"
  end

  add_index "ao_messages", ["channel_id", "channel_relative_id"], :name => "index_ao_messages_on_channel_id_and_channel_relative_id"
  add_index "ao_messages", ["guid"], :name => "index_ao_messages_on_guid"

  create_table "applications", :force => true do |t|
    t.string   "name"
    t.integer  "account_id"
    t.string   "interface",     :default => "rss"
    t.text     "configuration"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "password"
    t.string   "salt"
  end

  create_table "at_messages", :force => true do |t|
    t.string   "from"
    t.string   "to"
    t.text     "body"
    t.string   "guid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "timestamp"
    t.integer  "account_id"
    t.integer  "tries",               :default => 0,         :null => false
    t.string   "subject"
    t.string   "state",               :default => "pending", :null => false
    t.string   "channel_relative_id"
    t.integer  "channel_id"
    t.text     "custom_attributes"
    t.integer  "application_id"
  end

  create_table "carriers", :force => true do |t|
    t.integer  "country_id"
    t.string   "name"
    t.string   "clickatell_name"
    t.string   "guid"
    t.string   "prefixes"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "channels", :force => true do |t|
    t.string   "name"
    t.string   "kind"
    t.integer  "account_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "configuration"
    t.string   "protocol"
    t.integer  "direction"
    t.boolean  "enabled",           :default => true
    t.integer  "metric",            :default => 100
    t.integer  "throttle"
    t.text     "custom_attributes"
    t.string   "at_rules"
  end

  create_table "clickatell_message_parts", :force => true do |t|
    t.string   "originating_isdn"
    t.datetime "timestamp"
    t.integer  "reference_number"
    t.integer  "part_count"
    t.integer  "part_number"
    t.string   "text"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "countries", :force => true do |t|
    t.string   "name"
    t.string   "iso2",         :limit => 2
    t.string   "iso3",         :limit => 3
    t.string   "phone_prefix"
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.string   "locked_tag"
  end

  create_table "managed_processes", :force => true do |t|
    t.integer  "account_id"
    t.string   "name"
    t.string   "start_command"
    t.string   "stop_command"
    t.string   "pid_file"
    t.string   "log_file"
    t.boolean  "enabled"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mobile_numbers", :force => true do |t|
    t.string   "number"
    t.integer  "country_id"
    t.integer  "carrier_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "qst_outgoing_messages", :force => true do |t|
    t.integer  "ao_message_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "channel_id"
  end

  add_index "qst_outgoing_messages", ["ao_message_id"], :name => "index_unread_ao_messages_on_guid"

  create_table "smpp_message_parts", :force => true do |t|
    t.integer  "reference_number"
    t.integer  "part_count"
    t.integer  "part_number"
    t.string   "text"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "channel_id"
  end

  add_index "smpp_message_parts", ["channel_id", "reference_number"], :name => "index_smpp_message_parts_on_channel_id_and_reference_number"

  create_table "twitter_channel_statuses", :force => true do |t|
    t.integer  "channel_id"
    t.integer  "last_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "worker_queues", :force => true do |t|
    t.string   "queue_name"
    t.string   "working_group"
    t.boolean  "ack"
    t.boolean  "enabled",       :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
