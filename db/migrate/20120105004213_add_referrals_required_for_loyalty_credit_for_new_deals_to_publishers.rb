class AddReferralsRequiredForLoyaltyCreditForNewDealsToPublishers < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :publishers, :referrals_required_for_loyalty_credit_for_new_deals, :integer
  end

  def self.down
    remove_column_using_tmp_table :publishers, :referrals_required_for_loyalty_credit_for_new_deals
  end
end
