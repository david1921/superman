class AddCreditResetAtToConsumers < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :users, :credit_available_reset_at, :datetime
  end

  def self.down
    remove_column_using_tmp_table :users, :credit_available_reset_at
  end
end
