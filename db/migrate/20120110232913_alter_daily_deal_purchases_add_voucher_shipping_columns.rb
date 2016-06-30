class AlterDailyDealPurchasesAddVoucherShippingColumns < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :daily_deal_purchases, :mailing_address_id, :integer, :default => nil
    add_column_using_tmp_table :daily_deal_purchases, :fulfillment_method, :string, :default => "email"
    add_column_using_tmp_table :daily_deal_purchases, :voucher_shipping_amount, :decimal, :precision => 10, :scale => 2, :default => nil
  end

  def self.down
    remove_column_using_tmp_table :daily_deal_purchases, :mailing_address_id
    remove_column_using_tmp_table :daily_deal_purchases, :fulfillment_method
    remove_column_using_tmp_table :daily_deal_purchases, :voucher_shipping_amount
  end
end
