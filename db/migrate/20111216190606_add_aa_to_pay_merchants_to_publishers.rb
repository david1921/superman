class AddAaToPayMerchantsToPublishers < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :publishers, :aa_to_pay_merchants, :boolean
  end

  def self.down
    remove_column_using_tmp_table :publishers, :aa_to_pay_merchants    
  end
end
