class AddPrimaryOfToStores < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :stores, :primary_store_of_id, :integer
  end

  def self.down
    remove_column_using_tmp_table :stores, :primary_store_of_id
  end
end
