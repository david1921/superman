class AddSalesAgentIdToDailyDeals < ActiveRecord::Migration
  def self.up
		add_column_using_tmp_table :daily_deals, :sales_agent_id, :string  	
  end

  def self.down
  	remove_column_using_tmp_table :daily_deals, :sales_agent_id
  end
end
