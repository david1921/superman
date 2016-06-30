class AddCanManageConsumersToUsers < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :users, :can_manage_consumers, :boolean, :default => false
  end

  def self.down
    remove_column_using_tmp_table :users, :can_manage_consumers
  end
end
