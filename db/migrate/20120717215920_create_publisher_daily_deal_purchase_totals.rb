class CreatePublisherDailyDealPurchaseTotals < ActiveRecord::Migration
  def self.up
    create_table :publisher_daily_deal_purchase_totals do |t|
      t.string :publisher_label, :null => false
      t.integer :total, :null => false
      t.date :date, :null => false
    end
    add_index :publisher_daily_deal_purchase_totals, [:publisher_label, :date], :unique => true
    add_index :publisher_daily_deal_purchase_totals, :date, :unique => false
  end

  def self.down
    remove_index :publisher_daily_deal_purchase_totals, :date
    remove_index :publisher_daily_deal_purchase_totals, [:publisher_label, :date]
    drop_table :publisher_daily_deal_purchase_totals
  end
end
