class AddIndexOnDailyDealPurchasesExecutedAt < ActiveRecord::Migration
  def self.up
    add_index_using_tmp_table :daily_deal_purchases, :executed_at
    add_index_using_tmp_table :daily_deal_purchases, :certificate_email_sent_at
  end

  def self.down
    remove_index_using_tmp_table :daily_deal_purchases, :executed_at
    remove_index_using_tmp_table :daily_deal_purchases, :certificate_email_sent_at
  end
end
