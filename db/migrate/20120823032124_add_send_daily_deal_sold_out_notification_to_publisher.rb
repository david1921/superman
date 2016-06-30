class AddSendDailyDealSoldOutNotificationToPublisher < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :publishers, :send_daily_deal_notification, :boolean, :default => false
  end

  def self.down
    remove_column_using_tmp_table :publishers, :send_daily_deal_notification
  end
end
