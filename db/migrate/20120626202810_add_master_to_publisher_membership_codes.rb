class AddMasterToPublisherMembershipCodes < ActiveRecord::Migration
  def self.up
  	add_column_using_tmp_table :publisher_membership_codes, :master, :boolean, :default => false
  end

  def self.down
  	remove_column_using_tmp_table :publisher_membership_codes, :master
  end
end
