class AddCustomPaypalCancelReturnUrlToPublisher < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :publishers, :custom_paypal_cancel_return_url, :string
  end

  def self.down
    remove_column_using_tmp_table :publishers, :custom_paypal_cancel_return_url
  end
end
