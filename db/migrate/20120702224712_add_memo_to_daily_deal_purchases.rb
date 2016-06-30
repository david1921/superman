class AddMemoToDailyDealPurchases < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :daily_deal_purchases, :memo, :text
  end

  def self.down
    remove_column_using_tmp_table :daily_deal_purchases, :memo, :text
  end
end
