# frozen_string_literal: true

class CreateLegiscanCredit < ActiveRecord::Migration[7.0]
  def change
    create_table :legiscan_credits do |t|
      t.string :month, null: false
      t.integer :credits_used, default: 0, null: false
      t.timestamps
    end

    add_index :legiscan_credits, :month, unique: true
  end
end
