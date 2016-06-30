class AddPurchaseIncrementAmountToDailyDeals < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :daily_deals, :purchase_increment_amount, :integer
  end

  def self.down
    remove_column_using_tmp_table :daily_deals, :purchase_increment_amount
  end
end
