class AddEnableDailyDealVariationsToPublishers < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :publishers, :enable_daily_deal_variations, :boolean, :default => false
  end

  def self.down
    remove_column_using_tmp_table :publishers, :enable_daily_deal_variations
  end
end
