class AddConsumerAndBillingFieldsToDailyDealPayment < ActiveRecord::Migration
  def self.up
    with_tmp_table :daily_deal_payments do |tmp_table_name|
      add_column tmp_table_name, :billing_address_line_1, :string
      add_column tmp_table_name, :billing_address_line_2, :string
      add_column tmp_table_name, :billing_city, :string
      add_column tmp_table_name, :billing_state, :string
      add_column tmp_table_name, :name_on_card, :string
      add_column tmp_table_name, :credit_card_bin, :string
    end
  end

  def self.down
    with_tmp_table :daily_deal_payments do |tmp_table_name|
      remove_column tmp_table_name, :billing_address_line_1
      remove_column tmp_table_name, :billing_address_line_2
      remove_column tmp_table_name, :billing_city
      remove_column tmp_table_name, :billing_state
      remove_column tmp_table_name, :name_on_card
      remove_column tmp_table_name, :credit_card_bin
    end
  end
end
