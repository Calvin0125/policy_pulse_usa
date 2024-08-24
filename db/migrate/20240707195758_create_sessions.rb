# frozen_string_literal: true

class CreateSessions < ActiveRecord::Migration[7.0]
  def change
    create_table :sessions do |t|
      t.datetime :start_date
      t.datetime :end_date
      t.integer :legiscan_session_id
      t.timestamps
    end
  end
end
