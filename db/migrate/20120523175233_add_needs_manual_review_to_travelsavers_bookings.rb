class AddNeedsManualReviewToTravelsaversBookings < ActiveRecord::Migration
  def self.up
  	add_column_using_tmp_table :travelsavers_bookings, :needs_manual_review, :boolean, :default => false
  end

  def self.down
  	remove_column_using_tmp_table :travelsavers_bookings, :needs_manual_review
  end
end
