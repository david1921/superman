class AddBookingDatesToTravelsaversBookings < ActiveRecord::Migration
  def self.up
    with_tmp_table :travelsavers_bookings do |travelsavers_bookings|
      add_column travelsavers_bookings, :service_start_date, :datetime
      add_column travelsavers_bookings, :service_end_date, :datetime
      add_index travelsavers_bookings, :service_start_date
      add_index travelsavers_bookings, :service_end_date
    end
  end

  def self.down
    with_tmp_table :travelsavers_bookings do |travelsavers_bookings|
      remove_column travelsavers_bookings, :service_start_date
      remove_column travelsavers_bookings, :service_end_date
      remove_index travelsavers_bookings, :service_start_date
      remove_index travelsavers_bookings, :service_end_date
    end
  end
end
