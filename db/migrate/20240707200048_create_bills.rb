class CreateBills < ActiveRecord::Migration[7.0]
  def change
    create_table :bills do |t|
      t.references :session, foreign_key: true
      t.integer :status
      t.datetime :status_last_updated
      t.string :summary
      t.integer :legiscan_bill_id
      t.integer :legiscan_doc_id
      t.timestamps
    end
  end
end
