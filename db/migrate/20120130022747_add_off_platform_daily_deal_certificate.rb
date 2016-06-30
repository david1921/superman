class AddOffPlatformDailyDealCertificate < ActiveRecord::Migration
  def self.up
    create_table :off_platform_daily_deal_certificates, :force => true do |t|
      t.belongs_to :consumer, :null => false, :default => nil
      t.string :download_url, :null => false, :default => nil
      t.datetime :executed_at, :null => false, :default => nil
      t.date :expires_on, :null => false, :default => nil
      t.string :line_item_name, :null => false, :default => nil
      t.string :redeemer_names, :null => false, :default => nil
      t.integer :quantity_excluding_refunds, :null => false, :default => nil
    end
    add_index :off_platform_daily_deal_certificates, :consumer_id
    add_index :off_platform_daily_deal_certificates, :executed_at
  end

  def self.down
    drop_table :off_platform_daily_deal_certificates
  end
end
