class AddCompanyRegistrationNumberToAdvertisers < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :advertisers, :company_registration_number, :string
  end

  def self.down
    remove_column_using_tmp_table :advertisers, :company_registration_number
  end
end
