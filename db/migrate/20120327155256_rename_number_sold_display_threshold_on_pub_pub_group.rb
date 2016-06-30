class RenameNumberSoldDisplayThresholdOnPubPubGroup < ActiveRecord::Migration
  def self.up
    change_column :publishers, :number_sold_display_threshold, :integer, :default => 5000
    change_column :publishing_groups, :number_sold_display_threshold, :integer, :default => 5000
    rename_column :publishers, :number_sold_display_threshold, :number_sold_display_threshold_default
    rename_column :publishing_groups, :number_sold_display_threshold, :number_sold_display_threshold_default
  end

  def self.down
    rename_column :publishers, :number_sold_display_threshold_default, :number_sold_display_threshold
    rename_column :publishing_groups, :number_sold_display_threshold_default, :number_sold_display_threshold
    change_column :publishers, :number_sold_display_threshold, :integer, :default => nil
    change_column :publishing_groups, :number_sold_display_threshold, :integer, :default => nil
  end
end
