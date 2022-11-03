# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_12_20_093602) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "records", id: :serial, force: :cascade do |t|
    t.string "band"
    t.string "title"
    t.string "cover"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "slug"
    t.string "wikipedia_url"
    t.string "quotationspage_url"
    t.string "flickr_url"
    t.integer "views", default: 0
  end

end
