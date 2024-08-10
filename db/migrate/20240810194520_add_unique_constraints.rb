class AddUniqueConstraints < ActiveRecord::Migration[7.0]
  def change
    add_index :bills, :legiscan_bill_id, unique: true
    add_index :bills, :legiscan_doc_id, unique: true
    add_index :sessions, :legiscan_session_id, unique: true
  end
end
