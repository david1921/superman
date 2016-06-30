class AddNumberPurchasedToOffPlatformPurchaseSummaries < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :off_platform_purchase_summaries, :number_purchased, :integer
  end
  
  def self.down
    remove_column_using_tmp_table :off_platform_purchase_summaries, :number_purchased
  end
end
