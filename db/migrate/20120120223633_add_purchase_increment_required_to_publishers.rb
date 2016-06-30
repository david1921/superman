class AddPurchaseIncrementRequiredToPublishers < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :publishers, :purchase_increment_required, :boolean, :default => false
  end

  def self.down
    remove_column_using_tmp_table :publishers, :purchase_increment_required
  end
end
