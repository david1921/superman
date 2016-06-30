class AddBusinessTradingNameToAdvertisers < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :advertisers, :business_trading_name, :string
  end

  def self.down
    remove_column_using_tmp_table :advertisers, :business_trading_name
  end
end
