class AddIndexesOnAdvertisers < ActiveRecord::Migration
  def self.up
    add_index_using_tmp_table :advertisers, :primary_store_id
  end

  def self.down
    remove_index_using_tmp_table :advertisers, :primary_store_id
  end
end
