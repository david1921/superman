class AddRegisteredCompanyNameToAdvertisers < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :advertisers, :registered_company_name, :string
  end

  def self.down
    remove_column_using_tmp_table :advertisers, :registered_company_name
  end
end
