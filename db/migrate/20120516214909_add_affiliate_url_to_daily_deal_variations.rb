class AddAffiliateUrlToDailyDealVariations < ActiveRecord::Migration
  def self.up
  	add_column :daily_deal_variations, :affiliate_url, :text
  end

  def self.down
  	remove_column :daily_deal_variations, :affiliate_url
  end
end
