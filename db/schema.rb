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

ActiveRecord::Schema[8.1].define(version: 2026_03_09_211427) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "quotes", force: :cascade do |t|
    t.string "author", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.integer "source_id", null: false
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.datetime "used_at"
    t.index ["source_id"], name: "index_quotes_on_source_id", unique: true
    t.index ["used_at"], name: "index_quotes_on_used_at"
  end

  create_table "records", id: :serial, force: :cascade do |t|
    t.string "band", null: false
    t.string "cover", null: false
    t.datetime "created_at", precision: nil
    t.string "flickr_url", null: false
    t.string "quotationspage_url", null: false
    t.string "slug", null: false
    t.string "title", null: false
    t.datetime "updated_at", precision: nil
    t.integer "views", default: 0, null: false
    t.string "wikipedia_url", null: false
    t.index ["slug"], name: "index_records_on_slug", unique: true
  end
end
