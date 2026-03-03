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

ActiveRecord::Schema[8.1].define(version: 2019_12_20_093602) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "records", id: :serial, force: :cascade do |t|
    t.string "band"
    t.string "cover"
    t.datetime "created_at", precision: nil
    t.string "flickr_url"
    t.string "quotationspage_url"
    t.string "slug"
    t.string "title"
    t.datetime "updated_at", precision: nil
    t.integer "views", default: 0
    t.string "wikipedia_url"
  end
end
