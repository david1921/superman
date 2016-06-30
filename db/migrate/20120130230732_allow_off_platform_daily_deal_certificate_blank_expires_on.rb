class AllowOffPlatformDailyDealCertificateBlankExpiresOn < ActiveRecord::Migration
  def self.up
    change_column :off_platform_daily_deal_certificates, :expires_on, :date, :default => nil, :null => true
  end

  def self.down
    change_column :off_platform_daily_deal_certificates, :expires_on, :date, :default => nil, :null => false
  end
end
