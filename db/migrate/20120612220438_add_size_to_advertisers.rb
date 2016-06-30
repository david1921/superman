class AddSizeToAdvertisers < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :advertisers, :size, :string, :default => nil
  end

  def self.down
    remove_column_using_tmp_table :advertisers, :size
  end
end
