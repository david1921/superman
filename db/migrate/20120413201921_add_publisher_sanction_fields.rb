class AddPublisherSanctionFields < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :publishers, :encrypted_federal_tax_id, :string
    add_column_using_tmp_table :publishers, :started_at, :datetime
    add_column_using_tmp_table :publishers, :launched_at, :datetime
    add_column_using_tmp_table :publishers, :terminated_at, :datetime
  end

  def self.down
    remove_column_using_tmp_table :publishers, :terminated_at
    remove_column_using_tmp_table :publishers, :launched_at
    remove_column_using_tmp_table :publishers, :started_at
    remove_column_using_tmp_table :publishers, :encrypted_federal_tax_id
  end
end
