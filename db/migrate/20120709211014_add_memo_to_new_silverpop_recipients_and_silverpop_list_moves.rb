class AddMemoToNewSilverpopRecipientsAndSilverpopListMoves < ActiveRecord::Migration
  def self.up
  	add_column_using_tmp_table :new_silverpop_recipients, :memo, :string
  	add_column_using_tmp_table :silverpop_list_moves, :memo, :string
  end

  def self.down
  	remove_column_using_tmp_table :new_silverpop_recipients, :memo
  	remove_column_using_tmp_table :silverpop_list_moves, :memo
  end
end
