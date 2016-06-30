class AddEnableForceValidConsumersToPublishingGroup < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :publishing_groups, :enable_force_valid_consumers, :boolean, :default => false
  end

  def self.down
    remove_column_using_tmp_table :publishing_groups, :enable_force_valid_consumers
  end
end
