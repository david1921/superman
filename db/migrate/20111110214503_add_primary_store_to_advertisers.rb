class AddPrimaryStoreToAdvertisers < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :advertisers, :primary_store_id, :integer
  end

  def self.down
    remove_column_using_tmp_table :advertisers, :primary_store_id
  end
end
