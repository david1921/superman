class AddLoyaltyProgramReferralCodeToDailyDealPurchases < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :daily_deal_purchases, :loyalty_program_referral_code, :string
  end

  def self.down
    remove_column_using_tmp_table :daily_deal_purchases, :loyalty_program_referral_code
  end
end
