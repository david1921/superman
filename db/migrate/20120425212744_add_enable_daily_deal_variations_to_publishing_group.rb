class AddEnableDailyDealVariationsToPublishingGroup < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :publishing_groups, :enable_daily_deal_variations, :boolean
  end

  def self.down
    remove_column_using_tmp_table :publishing_groups, :enable_daily_deal_variations
  end
end
