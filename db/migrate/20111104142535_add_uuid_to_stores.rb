class AddUuidToStores < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :stores, :uuid, :string
  end

  def self.down
    remove_column_using_tmp_table :stores, :uuid
  end
end
