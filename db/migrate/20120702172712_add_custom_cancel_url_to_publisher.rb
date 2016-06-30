class AddCustomCancelUrlToPublisher < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :publishers, :custom_cancel_url, :string
  end

  def self.down
    remove_column_using_tmp_table :publishers, :custom_cancel_url
  end
end
