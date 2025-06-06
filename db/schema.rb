# frozen_string_literal: true

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

ActiveRecord::Schema[7.0].define(version: 20_250_513_003_206) do
  # These are extensions that must be enabled in order to support this database
  enable_extension 'plpgsql'

  create_table 'bills', force: :cascade do |t|
    t.bigint 'session_id', null: false
    t.integer 'status', null: false
    t.datetime 'status_last_updated'
    t.string 'summary'
    t.integer 'legiscan_bill_id', null: false
    t.integer 'legiscan_doc_id'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.string 'title', null: false
    t.index ['legiscan_bill_id'], name: 'index_bills_on_legiscan_bill_id', unique: true
    t.index ['legiscan_doc_id'], name: 'index_bills_on_legiscan_doc_id', unique: true
    t.index ['session_id'], name: 'index_bills_on_session_id'
    t.index ['title'], name: 'index_bills_on_title', unique: true
  end

  create_table 'legiscan_credits', force: :cascade do |t|
    t.string 'month', null: false
    t.integer 'credits_used', default: 0, null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['month'], name: 'index_legiscan_credits_on_month', unique: true
  end

  create_table 'sessions', force: :cascade do |t|
    t.datetime 'start_date', null: false
    t.datetime 'end_date', null: false
    t.integer 'legiscan_session_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['legiscan_session_id'], name: 'index_sessions_on_legiscan_session_id', unique: true
  end

  add_foreign_key 'bills', 'sessions'
end
