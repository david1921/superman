class AddBarCodeEncodingFormatToDailyDealVariations < ActiveRecord::Migration
  def self.up
  	add_column :daily_deal_variations, :bar_code_encoding_format, :integer, :default => 7, :null => false
  end

  def self.down
  	remove_column :daily_deal_variations, :bar_code_encoding_format
  end
end
