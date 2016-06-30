class AddQuantityFieldsToDailyDealVariations < ActiveRecord::Migration
  def self.up
  	add_column :daily_deal_variations, :quantity, :integer
  	add_column :daily_deal_variations, :min_quantity, :integer
  	add_column :daily_deal_variations, :max_quantity, :integer
  end

  def self.down
  	remove_column :daily_deal_variations, :quantity
  	remove_column :daily_deal_variations, :min_quantity
  	remove_column :daily_deal_variations, :max_quantity
  end
end
