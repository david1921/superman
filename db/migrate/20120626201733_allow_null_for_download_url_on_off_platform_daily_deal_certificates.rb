class AllowNullForDownloadUrlOnOffPlatformDailyDealCertificates < ActiveRecord::Migration
  def self.up
    change_column :off_platform_daily_deal_certificates, :download_url, :string, :null => true
  end

  def self.down
    change_column :off_platform_daily_deal_certificates, :download_url, :string
  end
end