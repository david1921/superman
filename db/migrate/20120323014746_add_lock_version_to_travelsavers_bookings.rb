class AddLockVersionToTravelsaversBookings < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :travelsavers_bookings, :lock_version, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column_using_tmp_table :travelsavers_bookings, :lock_version 
  end
end
