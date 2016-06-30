class AddGrossAnnualTurnoverToAdvertisers < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :advertisers, :gross_annual_turnover, :decimal, :precision => 10, :scale => 2
  end

  def self.down
    remove_column_using_tmp_table :advertisers, :gross_annual_turnover
  end
end
