class AddIndexesOnStores < ActiveRecord::Migration
  def self.up
    add_index_using_tmp_table :stores, :primary_store_of_id
    add_index_using_tmp_table :stores, :uuid
  end

  def self.down
    remove_index_using_tmp_table :stores, :primary_store_of_id
    remove_index_using_tmp_table :stores, :uuid
  end
end
