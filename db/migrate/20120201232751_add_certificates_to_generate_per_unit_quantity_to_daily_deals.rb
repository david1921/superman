class AddCertificatesToGeneratePerUnitQuantityToDailyDeals < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :daily_deals, :certificates_to_generate_per_unit_quantity, :integer, :null => false, :default => 1
  end

  def self.down
    remove_column_using_tmp_table :daily_deals, :certificates_to_generate_per_unit_quantity
  end
end
