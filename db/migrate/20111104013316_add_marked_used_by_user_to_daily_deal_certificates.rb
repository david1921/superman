class AddMarkedUsedByUserToDailyDealCertificates < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :daily_deal_certificates, :marked_used_by_user, :boolean, :default => false
  end

  def self.down
    remove_column_using_tmp_table :daily_deal_certificates, :marked_used_by_user
  end
end
