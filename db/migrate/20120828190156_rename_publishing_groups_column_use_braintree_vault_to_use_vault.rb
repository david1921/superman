class RenamePublishingGroupsColumnUseBraintreeVaultToUseVault < ActiveRecord::Migration
  def self.up
    with_tmp_table :publishing_groups do |tmp_table|
      rename_column tmp_table, :use_braintree_vault, :use_vault
    end
  end

  def self.down
    with_tmp_table :publishing_groups do |tmp_table|
      rename_column tmp_table, :use_vault, :use_braintree_vault
    end
  end
end
