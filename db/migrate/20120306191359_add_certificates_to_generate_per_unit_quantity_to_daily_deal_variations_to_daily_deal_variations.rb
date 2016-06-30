class AddCertificatesToGeneratePerUnitQuantityToDailyDealVariationsToDailyDealVariations < ActiveRecord::Migration
  def self.up
  	add_column :daily_deal_variations, :certificates_to_generate_per_unit_quantity, :integer, :default => 1, :null => false
  end

  def self.down
  	remove_column :daily_deal_variations, :certificates_to_generate_per_unit_quantity
  end
end
