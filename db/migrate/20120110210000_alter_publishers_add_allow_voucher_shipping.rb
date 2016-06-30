class AlterPublishersAddAllowVoucherShipping < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :publishers, :allow_voucher_shipping, :boolean, :default => false
  end

  def self.down
    remove_column_using_tmp_table :publishers, :allow_voucher_shipping
  end
end
