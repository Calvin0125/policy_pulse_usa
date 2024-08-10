class AddTitleToBills < ActiveRecord::Migration[7.0]
  def change
    add_column :bills, :title, :string, null: false
    add_index :bills, :title, unique: true
  end
end
