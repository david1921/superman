class RemoveDefaultFromNumberSoldDisplayThreshold < ActiveRecord::Migration
  def self.up
    # The current default is 5000 and it's making the settings on publisher and publishing_group useless
    change_column :daily_deals, :number_sold_display_threshold, :integer, :default => nil
  end

  def self.down
    change_column :daily_deals, :number_sold_display_threshold, :integer, :default => 5000
  end
end
