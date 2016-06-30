class SideDealScheduling < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :daily_deals, :side_start_at, :datetime
    add_column_using_tmp_table :daily_deals, :side_end_at, :datetime

    add_index_using_tmp_table :daily_deals, :side_start_at
    add_index_using_tmp_table :daily_deals, :side_end_at
  end

  def self.down
    remove_index_using_tmp_table :daily_deals, :side_start_at
    remove_index_using_tmp_table :daily_deals, :side_end_at

    remove_column_using_tmp_table :daily_deals, :side_start_at
    remove_column_using_tmp_table :daily_deals, :side_end_at
  end
end
