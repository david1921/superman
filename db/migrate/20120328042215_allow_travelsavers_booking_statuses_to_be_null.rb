class AllowTravelsaversBookingStatusesToBeNull < ActiveRecord::Migration
  def self.up
    change_column :travelsavers_bookings, :booking_status, :string, :null => true
    change_column :travelsavers_bookings, :payment_status, :string, :null => true
  end

  def self.down
    change_column :travelsavers_bookings, :booking_status, :string, :null => false
    change_column :travelsavers_bookings, :payment_status, :string, :null => false
  end
end
