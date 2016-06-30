class AddStatusToDailyDeals < ActiveRecord::Migration
  def self.up
  	add_column_using_tmp_table :daily_deals, :status, :string
  end

  def self.down
  	remove_column_using_tmp_table :daily_deals, :status
  end
end
