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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140910080153) do

  create_table "accounts", :force => true do |t|
    t.string   "name"
    t.string   "password"
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
    t.string   "salt"
    t.integer  "max_tries",         :default => 3, :null => false
    t.text     "app_routing_rules"
    t.text     "alert_emails"
  end

  create_table "address_sources", :force => true do |t|
    t.integer  "account_id"
    t.string   "address"
    t.integer  "channel_id"
    t.datetime "timestamp"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
    t.integer  "application_id"
  end

  add_index "address_sources", ["application_id", "address", "channel_id"], :name => "address_sources_idx", :unique => true

  create_table "ao_message_fragments", :force => true do |t|
    t.integer  "account_id"
    t.integer  "channel_id"
    t.integer  "ao_message_id"
    t.string   "fragment_id"
    t.integer  "number"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "ao_message_fragments", ["account_id", "channel_id", "fragment_id", "number"], :name => "index_ao_message_fragments"

  create_table "ao_messages", :force => true do |t|
    t.string   "from"
    t.string   "to"
    t.text     "body"
    t.datetime "created_at",                                               :null => false
    t.datetime "updated_at",                                               :null => false
    t.string   "guid"
    t.datetime "timestamp"
    t.integer  "account_id"
    t.integer  "tries",                             :default => 0,         :null => false
    t.string   "subject"
    t.string   "state",                             :default => "pending", :null => false
    t.string   "channel_relative_id"
    t.integer  "channel_id"
    t.text     "custom_attributes"
    t.integer  "application_id"
    t.integer  "parent_id"
    t.text     "failover_channels"
    t.text     "original"
    t.string   "token",               :limit => 36
  end

  add_index "ao_messages", ["account_id", "state", "channel_id"], :name => "index_ao_messages_on_account_id_and_state_and_channel_id"
  add_index "ao_messages", ["account_id", "to", "id"], :name => "index_ao_messages_on_account_id_and_to_and_id"
  add_index "ao_messages", ["application_id", "token"], :name => "index_ao_messages_on_application_id_and_token"
  add_index "ao_messages", ["channel_id", "channel_relative_id"], :name => "index_ao_messages_on_channel_id_and_channel_relative_id"
  add_index "ao_messages", ["guid"], :name => "index_ao_messages_on_guid"

  create_table "applications", :force => true do |t|
    t.string   "name"
    t.integer  "account_id"
    t.string   "interface",     :default => "rss"
    t.text     "configuration"
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
    t.string   "password"
    t.string   "salt"
    t.text     "ao_rules"
    t.text     "at_rules"
  end

  create_table "at_messages", :force => true do |t|
    t.string   "from"
    t.string   "to"
    t.text     "body"
    t.string   "guid"
    t.datetime "created_at",                                 :null => false
    t.datetime "updated_at",                                 :null => false
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

  add_index "at_messages", ["account_id", "channel_id", "timestamp"], :name => "index_at_messages_on_account_id_and_channel_id_and_timestamp"
  add_index "at_messages", ["account_id", "from", "id"], :name => "index_at_messages_on_account_id_and_from_and_id"
  add_index "at_messages", ["account_id", "guid"], :name => "index_at_messages_on_account_id_and_guid"

  create_table "carriers", :force => true do |t|
    t.integer  "country_id"
    t.string   "name"
    t.string   "clickatell_name"
    t.string   "guid"
    t.string   "prefixes"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  create_table "channels", :force => true do |t|
    t.string   "name"
    t.string   "kind"
    t.integer  "account_id"
    t.datetime "created_at",                                                         :null => false
    t.datetime "updated_at",                                                         :null => false
    t.text     "configuration"
    t.string   "protocol"
    t.integer  "direction"
    t.boolean  "enabled",                                         :default => true
    t.integer  "priority",                                        :default => 100
    t.integer  "throttle"
    t.text     "restrictions"
    t.text     "at_rules"
    t.integer  "application_id"
    t.string   "address"
    t.text     "ao_rules"
    t.boolean  "paused",                                          :default => false
    t.decimal  "ao_cost",          :precision => 10, :scale => 2
    t.decimal  "at_cost",          :precision => 10, :scale => 2
    t.datetime "last_activity_at"
  end

  add_index "channels", ["account_id", "name"], :name => "index_channels_on_account_id_and_name"

  create_table "clickatell_coverage_mos", :force => true do |t|
    t.integer  "country_id"
    t.integer  "carrier_id"
    t.string   "network"
    t.decimal  "cost",       :precision => 10, :scale => 2
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
  end

  create_table "clickatell_message_parts", :force => true do |t|
    t.string   "originating_isdn"
    t.datetime "timestamp"
    t.integer  "reference_number"
    t.integer  "part_count"
    t.integer  "part_number"
    t.string   "text"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  create_table "countries", :force => true do |t|
    t.string   "name"
    t.string   "iso2",            :limit => 2
    t.string   "iso3",            :limit => 3
    t.string   "phone_prefix"
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
    t.string   "clickatell_name"
    t.text     "area_codes"
  end

  create_table "cron_tasks", :force => true do |t|
    t.integer  "interval"
    t.datetime "next_run"
    t.datetime "last_run"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
    t.integer  "parent_id"
    t.string   "parent_type", :limit => 60
    t.string   "code"
    t.string   "name"
    t.string   "locked_tag"
  end

  add_index "cron_tasks", ["next_run"], :name => "index_cron_tasks_on_next_run"

  create_table "custom_attributes", :force => true do |t|
    t.integer  "account_id"
    t.string   "address"
    t.text     "custom_attributes"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  add_index "custom_attributes", ["account_id", "address"], :name => "index_custom_attributes_on_account_id_and_address", :unique => true

  create_table "identities", :force => true do |t|
    t.integer  "user_id"
    t.string   "provider"
    t.string   "token"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "logs", :force => true do |t|
    t.integer  "account_id"
    t.integer  "channel_id"
    t.integer  "ao_message_id"
    t.integer  "at_message_id"
    t.text     "message"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
    t.integer  "severity"
    t.integer  "application_id"
  end

  add_index "logs", ["account_id", "ao_message_id"], :name => "index_account_logs_on_account_id_and_ao_message_id"
  add_index "logs", ["account_id", "at_message_id"], :name => "index_account_logs_on_account_id_and_at_message_id"
  add_index "logs", ["account_id", "channel_id"], :name => "index_account_logs_on_account_id_and_channel_id"
  add_index "logs", ["account_id", "id"], :name => "index_account_logs_on_account_id_and_id"

  create_table "mobile_numbers", :force => true do |t|
    t.string   "number"
    t.integer  "country_id"
    t.integer  "carrier_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "qst_outgoing_messages", :force => true do |t|
    t.integer  "ao_message_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.integer  "channel_id"
  end

  add_index "qst_outgoing_messages", ["ao_message_id"], :name => "index_unread_ao_messages_on_guid"

  create_table "scheduled_jobs", :force => true do |t|
    t.text     "job"
    t.datetime "run_at"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "scheduled_jobs", ["run_at"], :name => "index_scheduled_jobs_on_run_at"

  create_table "smpp_message_parts", :force => true do |t|
    t.integer  "reference_number"
    t.integer  "part_count"
    t.integer  "part_number"
    t.string   "text"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
    t.integer  "channel_id"
    t.string   "source"
  end

  add_index "smpp_message_parts", ["channel_id", "source", "reference_number"], :name => "index_smpp_message_parts"

  create_table "tickets", :force => true do |t|
    t.string   "code"
    t.string   "secret_key"
    t.string   "status"
    t.text     "data"
    t.datetime "expiration"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "twitter_channel_statuses", :force => true do |t|
    t.integer  "channel_id"
    t.string   "last_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "user_accounts", :force => true do |t|
    t.integer  "user_id"
    t.integer  "account_id"
    t.string   "role"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "user_applications", :force => true do |t|
    t.integer  "account_id"
    t.integer  "user_id"
    t.integer  "application_id"
    t.string   "role"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  create_table "user_channels", :force => true do |t|
    t.integer  "account_id"
    t.integer  "user_id"
    t.integer  "channel_id"
    t.string   "role"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "email",                                 :default => "", :null => false
    t.string   "encrypted_password",     :limit => 128, :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                         :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.datetime "created_at",                                            :null => false
    t.datetime "updated_at",                                            :null => false
    t.integer  "current_account_id"
    t.string   "name"
    t.string   "authentication_token"
  end

  add_index "users", ["confirmation_token"], :name => "index_users_on_confirmation_token", :unique => true
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "whitelists", :force => true do |t|
    t.integer  "account_id"
    t.integer  "channel_id"
    t.string   "address"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "whitelists", ["account_id", "channel_id", "address"], :name => "index_whitelists_on_account_id_and_channel_id_and_address"

  create_table "worker_queues", :force => true do |t|
    t.string   "queue_name"
    t.string   "working_group"
    t.boolean  "ack"
    t.boolean  "enabled",       :default => true
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
    t.boolean  "durable",       :default => true
  end

end
