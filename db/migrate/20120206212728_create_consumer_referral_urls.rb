class CreateConsumerReferralUrls < ActiveRecord::Migration
  def self.up
    create_table :consumer_referral_urls do |t|
      t.references :consumer
      t.references :publisher
      t.string :bit_ly_url
      t.timestamps
    end

  end

  def self.down
    drop_table :consumer_referral_urls
  end
end
