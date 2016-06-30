class CreateTravelsaversBookings < ActiveRecord::Migration
  def self.up
    create_table :travelsavers_bookings do |t|
      t.belongs_to :daily_deal_purchase, :null => false
      t.string :book_transaction_url, :null => false
      t.text :book_transaction_xml
      t.string :booking_status, :null => false
      t.string :payment_status, :null => false
      t.timestamps
    end

    add_index :travelsavers_bookings, :daily_deal_purchase_id
    add_index :travelsavers_bookings, :booking_status
    add_index :travelsavers_bookings, :payment_status
  end

  def self.down
    drop_table :travelsavers_bookings
  end
end
