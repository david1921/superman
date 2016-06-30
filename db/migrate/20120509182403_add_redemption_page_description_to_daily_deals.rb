class AddRedemptionPageDescriptionToDailyDeals < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :daily_deal_translations, :redemption_page_description, :text
  end

  def self.down
    remove_column_using_tmp_table :daily_deal_translations, :redemption_page_description
  end
end
