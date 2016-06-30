class AddMemoToCredits < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :credits, :memo, :text
  end

  def self.down
    remove_column_using_tmp_table :credits, :memo
  end
end
