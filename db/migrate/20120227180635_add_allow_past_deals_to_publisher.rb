class AddAllowPastDealsToPublisher < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :publishers, :allow_past_deals_page, :boolean, :default => false
  end

  def self.down
    remove_column_using_tmp_table :publishers, :allow_past_deals_page
  end
end
