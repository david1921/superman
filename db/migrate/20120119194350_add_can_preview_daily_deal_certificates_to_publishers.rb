class AddCanPreviewDailyDealCertificatesToPublishers < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :publishers, :can_preview_daily_deal_certificates, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column_using_tmp_table :publishers, :can_preview_daily_deal_certificates
  end
end
