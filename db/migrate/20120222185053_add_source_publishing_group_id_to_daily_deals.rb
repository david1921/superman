class AddSourcePublishingGroupIdToDailyDeals < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :daily_deals, :source_publishing_group_id, :integer
  end

  def self.down
    remove_column_using_tmp_table :daily_deals, :source_publishing_group_id
  end
end
