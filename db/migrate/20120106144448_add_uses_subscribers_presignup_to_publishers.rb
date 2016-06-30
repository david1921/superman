class AddUsesSubscribersPresignupToPublishers < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :publishers, :uses_daily_deal_subscribers_presignup, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column_using_tmp_table :publishers, :uses_daily_deal_subscribers_presignup
  end
end
