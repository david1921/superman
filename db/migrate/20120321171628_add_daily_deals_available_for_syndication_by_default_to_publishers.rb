class AddDailyDealsAvailableForSyndicationByDefaultToPublishers < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :publishers, :daily_deals_available_for_syndication_by_default_override, :boolean, :default => nil
  end

  def self.down
    remove_column_using_tmp_table :publishers, :daily_deals_available_for_syndication_by_default_override
  end
end
