class AddSourceIndexesToDailyDeal < ActiveRecord::Migration
  def self.up
    add_index :daily_deals, :source_publisher_id
    add_index :daily_deals, :source_publishing_group_id
  end

  def self.down
    remove_index :daily_deals, :source_publisher_id
    remove_index :daily_deals, :source_publishing_group_id
  end
end
