class AddSourceChannelToDailyDeals < ActiveRecord::Migration
  def self.up
  	add_column_using_tmp_table :daily_deals, :source_channel, :string
  end

  def self.down
  	remove_column_using_tmp_table :daily_deals, :source_channel
  end
end
