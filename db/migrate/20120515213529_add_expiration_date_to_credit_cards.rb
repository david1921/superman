class AddExpirationDateToCreditCards < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :credit_cards, :expiration_date, :date
  end

  def self.down
    remove_column_using_tmp_table :credit_cards, :expiration_date
  end
end
