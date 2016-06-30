class AddEnableLoyaltyProgramToDailyDeals < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :daily_deals, :enable_loyalty_program, :boolean
  end

  def self.down
    remove_column_using_tmp_table :daily_deals, :enable_loyalty_program
  end
end
