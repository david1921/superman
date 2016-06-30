class AddMainPublisherColumnsToPublishersAndPublishingGroups < ActiveRecord::Migration
  def self.up
  	add_column_using_tmp_table :publishers, :main_publisher, :boolean, :default => false
  	add_column_using_tmp_table :publishing_groups, :enable_redirect_to_main_publisher, :boolean, :default => false
  end

  def self.down
  	remove_column_using_tmp_table :publishers, :main_publisher
  	remove_column_using_tmp_table :publishing_groups, :enable_redirect_to_main_publisher
  end
end
