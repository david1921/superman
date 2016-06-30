class SleepingMigrationForProductionTest < ActiveRecord::Migration
  def self.up
    sleep 60
  end

  def self.down
  end
end
