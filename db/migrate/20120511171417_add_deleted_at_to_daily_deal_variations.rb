class AddDeletedAtToDailyDealVariations < ActiveRecord::Migration
  def self.up
    add_column :daily_deal_variations, :deleted_at, :datetime
  end

  def self.down
    remove_column :daily_deal_variations, :deleted_at
  end
end
