class AddTravelsaversProductCodeToDailyDealVariations < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :daily_deal_variations, :travelsavers_product_code, :string
  end

  def self.down
    remove_column_using_tmp_table :daily_deal_variations, :travelsavers_product_code
  end
end
