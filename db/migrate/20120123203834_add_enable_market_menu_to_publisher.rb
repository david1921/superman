class AddEnableMarketMenuToPublisher < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :publishers, :enable_market_menu, :boolean
  end
  def self.down
    remove_column_using_tmp_table :publishers, :enable_market_menu
  end
end
