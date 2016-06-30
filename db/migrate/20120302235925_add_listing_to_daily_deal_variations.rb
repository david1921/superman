class AddListingToDailyDealVariations < ActiveRecord::Migration
  def self.up
  	add_column :daily_deal_variations, :listing, :string
  end

  def self.down
  	remove_column :daily_deal_variations, :listing
  end
end
