class AddDailyDealVariationIdToDailyDealPurchases < ActiveRecord::Migration
  def self.up
  	add_column_using_tmp_table :daily_deal_purchases, :daily_deal_variation_id, :integer
  end

  def self.down
  	remove_column_using_tmp_table :daily_deal_purchases, :daily_deal_variation_id
  end
end
