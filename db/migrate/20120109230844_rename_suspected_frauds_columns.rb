class RenameSuspectedFraudsColumns < ActiveRecord::Migration
  def self.up
    remove_index :suspected_frauds, :daily_deal_purchase_1_id
    remove_index :suspected_frauds, :daily_deal_purchase_2_id
    
    change_table :suspected_frauds do |t|
      t.rename :daily_deal_purchase_1_id, :suspect_daily_deal_purchase_id
      t.rename :daily_deal_purchase_2_id, :matched_daily_deal_purchase_id
    end
    add_index :suspected_frauds, :suspect_daily_deal_purchase_id, :unique => true
    add_index :suspected_frauds, :matched_daily_deal_purchase_id
  end

  def self.down
    remove_index :suspected_frauds, :suspect_daily_deal_purchase_id
    remove_index :suspected_frauds, :matched_daily_deal_purchase_id
    
    change_table :suspected_frauds do |t|
      t.rename :suspect_daily_deal_purchase_id, :daily_deal_purchase_1_id
      t.rename :matched_daily_deal_purchase_id, :daily_deal_purchase_2_id
    end
    add_index :suspected_frauds, :daily_deal_purchase_1_id
    add_index :suspected_frauds, :daily_deal_purchase_2_id
  end
end
