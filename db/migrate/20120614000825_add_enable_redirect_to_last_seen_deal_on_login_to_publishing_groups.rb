class AddEnableRedirectToLastSeenDealOnLoginToPublishingGroups < ActiveRecord::Migration
  def self.up
  	add_column_using_tmp_table :publishing_groups, :enable_redirect_to_last_seen_deal_on_login, :boolean, :default => false
  end

  def self.down
  	remove_column_using_tmp_table :publishing_groups, :enable_redirect_to_last_seen_deal_on_login
  end
end
