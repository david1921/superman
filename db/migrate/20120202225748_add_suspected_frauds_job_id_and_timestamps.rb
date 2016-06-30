class AddSuspectedFraudsJobIdAndTimestamps < ActiveRecord::Migration
  def self.up
    change_table :suspected_frauds do |t|
      t.belongs_to :job
      t.timestamps
    end
    add_index :suspected_frauds, :job_id
  end

  def self.down
    change_table :suspected_frauds do |t|
      t.remove :job
      t.remove_timestamps
    end
  end
end
