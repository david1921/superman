class AddIndexesToConsumerReferralUrls < ActiveRecord::Migration
  def self.up
    add_index_using_tmp_table :consumer_referral_urls, :publisher_id
    add_index_using_tmp_table :consumer_referral_urls, :consumer_id
  end

  def self.down
    remove_index_using_tmp_table :consumer_referral_urls, :publisher_id
    remove_index_using_tmp_table :consumer_referral_urls, :consumer_id
  end
end
