class AddNonVoucherDealToDailyDeals < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :daily_deals, :non_voucher_deal, :boolean
  end

  def self.down
    remove_column_using_tmp_table :daily_deals, :non_voucher_deal
  end
end
