class AddPublishingGroupVoucherHasQrCodeDefault < ActiveRecord::Migration
  def self.up
  	add_column :publishing_groups, :voucher_has_qr_code_default, :boolean, :null => false, :default => false
  	change_column_default :daily_deals, :voucher_has_qr_code, nil
  	execute "update daily_deals set voucher_has_qr_code = false where voucher_has_qr_code is null"
  end

  def self.down
  	remove_column :publishing_groups, :voucher_has_qr_code_default
  	change_column_default :daily_deals, :voucher_has_qr_code, false
  end
end
