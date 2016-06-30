class AddPayAllLocationsToAdvertisers < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :advertisers, :pay_all_locations, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column_using_tmp_table :advertisers, :pay_all_locations
  end
end
