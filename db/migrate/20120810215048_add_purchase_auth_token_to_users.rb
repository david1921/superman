class AddPurchaseAuthTokenToUsers < ActiveRecord::Migration
  def self.up
    with_tmp_table :users do |tmp_table|
      add_column tmp_table, :purchase_auth_token, :string
    end
  end

  def self.down
    with_tmp_table :users do |tmp_table|
      remove_column tmp_table, :purchase_auth_token
    end
  end
end
