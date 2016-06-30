class AddShowStatusesToPublishers < ActiveRecord::Migration
  def self.up
  	add_column_using_tmp_table :publishers, :enable_advertiser_statuses, :boolean, :default => false
  end

  def self.down
  	remove_column_using_tmp_table :publishers, :enable_advertiser_statuses
  end
end
