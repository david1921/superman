class AddTypeIndexToDailyDeals < ActiveRecord::Migration
  def self.up
    add_index_using_tmp_table :daily_deals, :type
  end

  def self.down
    remove_index_using_tmp_table :daily_deals, :type
  end
end
