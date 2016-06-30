class AddUsedForTestingFieldsToPublishersAndAdvertisers < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :publishers, :used_exclusively_for_testing, :boolean, :default => false
    add_column_using_tmp_table :advertisers, :used_exclusively_for_testing, :boolean, :default => false
  end

  def self.down
    remove_column_using_tmp_table :publishers, :used_exclusively_for_testing
    remove_column_using_tmp_table :advertisers, :used_exclusively_for_testing
  end
end
