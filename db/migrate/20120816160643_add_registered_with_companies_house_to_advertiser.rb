class AddRegisteredWithCompaniesHouseToAdvertiser < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :advertisers, :registered_with_companies_house, :boolean, :default => false
  end

  def self.down
    remove_column_using_tmp_table :advertisers, :registered_with_companies_house
  end
end
