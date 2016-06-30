class ChangeDailyDealVariationsTableToNotAllowNullOnDailyDealId < ActiveRecord::Migration
  def self.up
  	change_column :daily_deal_variations, :daily_deal_id, :integer, :null => false
  end

  def self.down
  	change_column :daily_deal_variations, :daily_deal_id, :integer, :null => true
  end
end
