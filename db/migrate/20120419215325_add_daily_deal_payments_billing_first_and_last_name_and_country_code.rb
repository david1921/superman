class AddDailyDealPaymentsBillingFirstAndLastNameAndCountryCode < ActiveRecord::Migration
  def self.up
    with_tmp_table :daily_deal_payments do |tmp_table_name|
      add_column tmp_table_name, :billing_first_name, :string
      add_column tmp_table_name, :billing_last_name, :string
      add_column tmp_table_name, :billing_country_code, :string, :limit => 2
    end
  end

  def self.down
    with_tmp_table :daily_deal_payments do |tmp_table_name|
      remove_column tmp_table_name, :billing_country_code
      remove_column tmp_table_name, :billing_last_name
      remove_column tmp_table_name, :billing_first_name
    end
  end
end
