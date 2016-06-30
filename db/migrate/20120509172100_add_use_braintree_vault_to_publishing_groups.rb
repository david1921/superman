class AddUseBraintreeVaultToPublishingGroups < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :publishing_groups, :use_braintree_vault, :boolean, :default => false
  end

  def self.down
    remove_column_using_tmp_table :publishing_groups, :use_braintree_vault
  end
end
