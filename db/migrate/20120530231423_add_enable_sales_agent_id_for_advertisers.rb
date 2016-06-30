class AddEnableSalesAgentIdForAdvertisers < ActiveRecord::Migration
  def self.up
  	add_column_using_tmp_table :publishers, :enable_sales_agent_id_for_advertisers, :boolean, :default => false
  end

  def self.down
  	remove_column_using_tmp_table :publishers, :enable_sales_agent_id_for_advertisers
  end
end
