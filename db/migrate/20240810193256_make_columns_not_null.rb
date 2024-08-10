class MakeColumnsNotNull < ActiveRecord::Migration[7.0]
  def change
    change_column_null :bills, :status, false
    change_column_null :bills, :legiscan_bill_id, false
    change_column_null :bills, :session_id, false
    change_column_null :sessions, :legiscan_session_id, false
    change_column_null :sessions, :start_date, false
    change_column_null :sessions, :end_date, false
  end
end
