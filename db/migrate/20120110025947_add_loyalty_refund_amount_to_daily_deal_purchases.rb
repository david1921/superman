class AddLoyaltyRefundAmountToDailyDealPurchases < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :daily_deal_purchases, :loyalty_refund_amount, :decimal, :precision => 10, :scale => 2
  end

  def self.down
    remove_column_using_tmp_table :daily_deal_purchases, :loyalty_refund_amount
  end
end
