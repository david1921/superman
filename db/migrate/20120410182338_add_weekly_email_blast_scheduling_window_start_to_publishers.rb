class AddWeeklyEmailBlastSchedulingWindowStartToPublishers < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :publishers, :weekly_email_blast_scheduling_window_start_in_hours, :integer, :default => 4
  end

  def self.down
    remove_column_using_tmp_table :publishers, :weekly_email_blast_scheduling_window_start_in_hours
  end
end
