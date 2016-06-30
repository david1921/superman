class AddIndexesForDailyDealVariations < ActiveRecord::Migration
  def self.up
  	add_index_using_tmp_table :daily_deal_variations, :daily_deal_id
  	add_index_using_tmp_table :daily_deal_purchases, :daily_deal_variation_id
  end

  def self.down
  	remove_index_using_tmp_table :daily_deal_variations, :daily_deal_id
  	remove_index_using_tmp_table :daily_deal_purchases, :daily_deal_variation_id  	
  end
end
