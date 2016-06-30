class RemoveDailyDealIdFromSuspectedFrauds < ActiveRecord::Migration
  def self.up
    remove_column :suspected_frauds, :daily_deal_id
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
