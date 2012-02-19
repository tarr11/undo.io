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

ActiveRecord::Schema.define(:version => 20120219181508) do

  create_table "alerts", :force => true do |t|
    t.integer  "user_id"
    t.text     "message"
    t.boolean  "was_read"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "alerts", ["user_id"], :name => "index_alerts_on_user_id"

  create_table "applications", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "beta_testers", :force => true do |t|
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "consumer_tokens", :force => true do |t|
    t.integer  "user_id"
    t.string   "type",           :limit => 30
    t.string   "token",          :limit => 1024
    t.string   "secret"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "authorized_at"
    t.datetime "invalidated_at"
    t.datetime "expires_at"
  end

  add_index "consumer_tokens", ["token"], :name => "index_consumer_tokens_on_token", :unique => true

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "dropbox_wrappers", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "shared_files", :force => true do |t|
    t.integer  "todo_file_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "viewed_file"
  end

  create_table "task_file_revisions", :force => true do |t|
    t.integer  "todo_file_id"
    t.text     "contents"
    t.string   "filename"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.datetime "revision_at"
    t.string   "dropbox_revision"
    t.text     "diff"
    t.datetime "summary"
    t.datetime "published_at"
  end

  create_table "tasks", :force => true do |t|
    t.string   "task"
    t.integer  "user_id"
    t.integer  "application_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "client_id"
  end

  create_table "todo_files", :force => true do |t|
    t.string   "filename"
    t.text     "contents"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "notes"
    t.datetime "revision_at"
    t.string   "dropbox_revision"
    t.text     "diff"
    t.boolean  "is_public"
    t.integer  "copied_from_id"
    t.string   "summary"
    t.datetime "published_at"
  end

  create_table "todo_lines", :force => true do |t|
    t.integer  "user_id"
    t.string   "line"
    t.string   "guid"
    t.integer  "todo_file_id"
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "time_zone"
    t.string   "username"
    t.string   "thumbnail"
    t.boolean  "show_shared_message"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "users", ["username"], :name => "index_users_on_username", :unique => true

end
