class AddReferralsRequiredForLoyaltyCreditToDailyDeals < ActiveRecord::Migration
  def self.up
    add_column :daily_deals, :referrals_required_for_loyalty_credit, :integer
  end

  def self.down
    remove_column :daily_deals, :referrals_required_for_loyalty_credit
  end
end
