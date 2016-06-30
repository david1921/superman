class AddPublishingGroupMaxQuantityDefault < ActiveRecord::Migration
  def self.up
  	add_column :publishing_groups, :max_quantity_default, :integer, :null => false, :default => 10
  	# NULL default would be better, but MySQL won't allow
  	change_column_default :daily_deals, :max_quantity, 0
  	execute "update daily_deals set max_quantity = 5 where publisher_id in (select id from publishers where publishing_group_id in (select id from publishing_groups where label='wcax'))"
  end

  def self.down
  	remove_column :publishing_groups, :max_quantity_default
  	change_column_default :daily_deals, :max_quantity, 10
  end
end
