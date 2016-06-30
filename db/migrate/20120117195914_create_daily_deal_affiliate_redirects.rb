class CreateDailyDealAffiliateRedirects < ActiveRecord::Migration
  def self.up
    create_table :daily_deal_affiliate_redirects do |t|
      t.references :daily_deal
      t.references :consumer
      t.timestamps
    end
  end

  def self.down
    drop_table :daily_deal_affiliate_redirects
  end
end
