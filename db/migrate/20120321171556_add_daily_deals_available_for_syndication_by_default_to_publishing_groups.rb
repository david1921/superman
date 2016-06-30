class AddDailyDealsAvailableForSyndicationByDefaultToPublishingGroups < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :publishing_groups, :daily_deals_available_for_syndication_by_default, :boolean, :default => false
  end

  def self.down
    remove_column_using_tmp_table :publishing_groups, :daily_deals_available_for_syndication_by_default
  end
end
