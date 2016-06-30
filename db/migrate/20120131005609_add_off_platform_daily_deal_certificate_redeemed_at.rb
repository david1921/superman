class AddOffPlatformDailyDealCertificateRedeemedAt < ActiveRecord::Migration
  def self.up
    add_column :off_platform_daily_deal_certificates, :redeemed_at, :datetime, :default => nil, :null => true
    add_column :off_platform_daily_deal_certificates, :redeemed, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :off_platform_daily_deal_certificates, :redeemed_at
    remove_column :off_platform_daily_deal_certificates, :redeemed
  end
end
