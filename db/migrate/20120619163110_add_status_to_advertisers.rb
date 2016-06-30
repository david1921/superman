class AddStatusToAdvertisers < ActiveRecord::Migration
  def self.up
  	add_column_using_tmp_table :advertisers, :status, :string
  	remove_column_using_tmp_table :advertisers, :approved
  	ActiveRecord::Base.connection.execute("update advertisers set status = 'approved';")
  end

  def self.down
  	remove_column_using_tmp_table :advertisers, :status
  	add_column_using_tmp_table :advertisers, :approved, :boolean, :default => false
  end
end
