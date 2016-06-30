class AddEnableFraudDetectionToPublishers < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :publishers, :enable_fraud_detection, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column_using_tmp_table :publishers, :enable_fraud_detection
  end
end
