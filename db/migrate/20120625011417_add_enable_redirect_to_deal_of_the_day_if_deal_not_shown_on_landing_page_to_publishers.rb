class AddEnableRedirectToDealOfTheDayIfDealNotShownOnLandingPageToPublishers < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :publishers, :enable_redirect_to_landing_if_deal_not_shown_on_landing_page, :boolean, :default => false
  end

  def self.down
    remove_column_using_tmp_table :publishers, :enable_redirect_to_landing_if_deal_not_shown_on_landing_page
  end
end