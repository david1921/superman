class AddAllowNonVoucherDealsToPublishingGroups < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :publishing_groups, :allow_non_voucher_deals, :boolean
  end

  def self.down
    remove_column_using_tmp_table :publishing_groups, :allow_non_voucher_deals
  end
end
