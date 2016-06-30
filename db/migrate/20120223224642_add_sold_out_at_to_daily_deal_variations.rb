class AddSoldOutAtToDailyDealVariations < ActiveRecord::Migration
  def self.up
  	add_column :daily_deal_variations, :sold_out_at, :datetime
  end

  def self.down
  	remove_column :daily_deal_variations, :sold_out_at
  end
end
