class AddNotificationEmailAddressToPublisher < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :publishers, :notification_email_address, :string
  end

  def self.down
    remove_column_using_tmp_table :publishers, :notification_email_address
  end
end
