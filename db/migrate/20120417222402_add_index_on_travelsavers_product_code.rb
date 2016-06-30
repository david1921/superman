class AddIndexOnTravelsaversProductCode < ActiveRecord::Migration
  def self.up
    add_index_using_tmp_table :daily_deals, :travelsavers_product_code
  end

  def self.down
    remove_index_using_tmp_table :daily_deals, :travelsavers_product_code
  end
end
