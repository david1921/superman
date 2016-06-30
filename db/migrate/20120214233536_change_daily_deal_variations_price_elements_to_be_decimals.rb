class ChangeDailyDealVariationsPriceElementsToBeDecimals < ActiveRecord::Migration
  def self.up
		change_column :daily_deal_variations, :value, :decimal, :precision => 10, :scale => 2, :null => false
		change_column :daily_deal_variations, :price, :decimal, :precision => 10, :scale => 2, :null => false
  end

  def self.down  	
		change_column :daily_deal_variations, :value, :integer
		change_column :daily_deal_variations, :price, :integer
  end
end
