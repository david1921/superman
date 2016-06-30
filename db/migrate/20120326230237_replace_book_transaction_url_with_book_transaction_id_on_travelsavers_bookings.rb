class ReplaceBookTransactionUrlWithBookTransactionIdOnTravelsaversBookings < ActiveRecord::Migration
  def self.up
    remove_column_using_tmp_table :travelsavers_bookings, :book_transaction_url
    add_column_using_tmp_table :travelsavers_bookings, :book_transaction_id, :string, :null => false
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
