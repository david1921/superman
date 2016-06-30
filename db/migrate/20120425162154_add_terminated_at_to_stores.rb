class AddTerminatedAtToStores < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :stores, :terminated_at, :datetime
  end

  def self.down
    remove_column_using_tmp_table :stores, :terminated_at
  end
end
