class AddIndexOnDailyDealsEnableLoyaltyProgram < ActiveRecord::Migration
  def self.up
    add_index_using_tmp_table :daily_deals, :enable_loyalty_program
    add_index_using_tmp_table :daily_deals, [:publisher_id, :enable_loyalty_program]
  end

  def self.down
    remove_index_using_tmp_table :daily_deals, :enable_loyalty_program
    remove_index_using_tmp_table :daily_deals, [:publisher_id, :enable_loyalty_program]
  end
end
