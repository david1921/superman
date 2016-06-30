class AddIndexesToSuspectedFrauds < ActiveRecord::Migration
  def self.up
    add_index :suspected_frauds, :daily_deal_purchase_1_id
    add_index :suspected_frauds, :daily_deal_purchase_2_id
  end

  def self.down
    remove_index :suspected_frauds, :daily_deal_purchase_1_id
    remove_index :suspected_frauds, :daily_deal_purchase_2_id
  end
end
