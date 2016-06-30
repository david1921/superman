class AddBillingInfoToCreditCards < ActiveRecord::Migration
  def self.up
    with_tmp_table :credit_cards do |tmp_table_name|
      add_column tmp_table_name, :billing_first_name, :string
      add_column tmp_table_name, :billing_last_name, :string
      add_column tmp_table_name, :billing_country_code, :string, :limit => 2
      add_column tmp_table_name, :billing_address_line_1, :string
      add_column tmp_table_name, :billing_address_line_2, :string
      add_column tmp_table_name, :billing_city, :string
      add_column tmp_table_name, :billing_state, :string
      add_column tmp_table_name, :billing_postal_code, :string
    end
  end

  def self.down
    with_tmp_table :credit_cards do |tmp_table_name|
      remove_column tmp_table_name, :billing_country_code
      remove_column tmp_table_name, :billing_last_name
      remove_column tmp_table_name, :billing_first_name
      remove_column tmp_table_name, :billing_address_line_1
      remove_column tmp_table_name, :billing_address_line_2
      remove_column tmp_table_name, :billing_city
      remove_column tmp_table_name, :billing_state
      remove_column tmp_table_name, :billing_postal_code
    end
  end
end
