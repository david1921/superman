class AddRedirectToLocalDealToPublishers < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :publishing_groups, :enable_redirect_to_local_deal, :boolean, :default => false
  end

  def self.down
    remove_column_using_tmp_table :publishing_groups, :enable_redirect_to_local_deal
  end
end
