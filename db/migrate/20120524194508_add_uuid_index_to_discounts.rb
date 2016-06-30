class AddUuidIndexToDiscounts < ActiveRecord::Migration
  def self.up
    add_index_using_tmp_table :discounts, :uuid
  end

  def self.down
    remove_index_using_tmp_table :discounts, :uuid
  end
end
