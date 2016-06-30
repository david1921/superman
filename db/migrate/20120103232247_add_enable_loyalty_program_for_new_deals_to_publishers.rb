class AddEnableLoyaltyProgramForNewDealsToPublishers < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :publishers, :enable_loyalty_program_for_new_deals, :boolean
  end

  def self.down
    remove_column_using_tmp_table :publishers, :enable_loyalty_program_for_new_deals
  end
end
