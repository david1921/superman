class CreateDailyDealVariations < ActiveRecord::Migration
  def self.up
    create_table :daily_deal_variations do |t|
      t.integer :daily_deal_id
      t.decimal :value
      t.decimal :price
      t.string :value_proposition

      t.timestamps
    end
  end

  def self.down
    drop_table :daily_deal_variations
  end
end
