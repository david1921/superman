class RemovePurchaseIncrementColumns < ActiveRecord::Migration
  def self.up
    remove_column_using_tmp_table :publishers, :purchase_increment_required
    remove_column_using_tmp_table :daily_deals, :purchase_increment_amount
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
