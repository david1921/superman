class AddSalesAgentIdToAdvertisers < ActiveRecord::Migration
  def self.up
  	add_column_using_tmp_table :advertisers, :sales_agent_id, :string
  end

  def self.down
  	remove_column_using_tmp_table :advertisers, :sales_agent_id
  end
end
