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

ActiveRecord::Schema[8.1].define(version: 2026_08_14_142629) do
  create_table "users", force: :cascade do |t|
    t.string "access_token", null: false
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.string "name"
    t.string "refresh_token", null: false
    t.string "strava_id", null: false
    t.integer "token_expires_at", null: false
    t.datetime "updated_at", null: false
    t.index ["strava_id"], name: "index_users_on_strava_id", unique: true
  end

  create_table "weekly_summaries", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.date "end_date"
    t.json "metrics"
    t.date "start_date"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "start_date", "end_date"], name: "index_weekly_summaries_on_user_id_and_start_date_and_end_date"
    t.index ["user_id"], name: "index_weekly_summaries_on_user_id"
  end

  add_foreign_key "weekly_summaries", "users"
end
