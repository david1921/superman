class AddBraintreeRedirectResultsType < ActiveRecord::Migration
  def self.up
    with_tmp_table(:braintree_redirect_results) do |tmp_table_name|
      add_column tmp_table_name, :type, :string, :default => "BraintreeGatewayResult"
    end
  end

  def self.down
    with_tmp_table(:braintree_redirect_results) do |tmp_table_name|
      remove_column tmp_table_name, :type
    end
  end
end
