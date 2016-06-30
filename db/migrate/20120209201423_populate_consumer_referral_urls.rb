class PopulateConsumerReferralUrls < ActiveRecord::Migration
  def self.up
    consumer_sql = "SELECT id, publisher_id, bit_ly_url
                    FROM users
                    WHERE bit_ly_url IS NOT NULL"

    select_all(consumer_sql).each do |consumer_hash|
      execute "INSERT INTO consumer_referral_urls
               (consumer_id, publisher_id, bit_ly_url, created_at, updated_at)
               VALUES (#{consumer_hash["id"]},
                       #{consumer_hash["publisher_id"]},
                       '#{consumer_hash["bit_ly_url"]}',
                       NOW(),
                       NOW());"
    end

  end

  def self.down
  end
end
