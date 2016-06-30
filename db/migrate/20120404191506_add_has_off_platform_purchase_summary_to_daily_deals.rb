class AddHasOffPlatformPurchaseSummaryToDailyDeals < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :daily_deals, :has_off_platform_purchase_summary, :boolean, :default => false
  end

  def self.down
    remove_column_using_tmp_table :daily_deals, :has_off_platform_purchase_summary
  end
end
