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

ActiveRecord::Schema.define(:version => 20110312103709) do

  create_table "merchants", :force => true do |t|
    t.string   "name"
    t.string   "city"
    t.string   "street"
    t.string   "location_link"
    t.string   "telephone_number"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "additional_data"
  end

  add_index "merchants", ["name"], :name => "merchants_name_index"

  create_table "search_paths", :force => true do |t|
    t.string   "search_string"
    t.string   "status"
    t.integer  "level"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "search_paths", ["search_string"], :name => "index_search_paths_on_search_string"

end
