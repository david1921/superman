class AddEnablePublisherTrackingToDailyDeal < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :daily_deals, :enable_publisher_tracking, :boolean, :default => true
  end

  def self.down
    remove_column_using_tmp_table :daily_deals, :enable_publisher_tracking
  end
end
