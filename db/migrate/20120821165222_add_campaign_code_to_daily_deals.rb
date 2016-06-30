class AddCampaignCodeToDailyDeals < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :daily_deals, :campaign_code, :string
  end

  def self.down
    remove_column_using_tmp_table :daily_deals, :campaign_code
  end
end
