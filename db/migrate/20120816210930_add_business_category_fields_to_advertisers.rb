class AddBusinessCategoryFieldsToAdvertisers < ActiveRecord::Migration
  def self.up
  	add_column_using_tmp_table :advertisers, :primary_business_category, :string
  	add_column_using_tmp_table :advertisers, :secondary_business_category, :string
  end

  def self.down
  	remove_column_using_tmp_table :advertisers, :primary_business_category
  	remove_column_using_tmp_table :advertisers, :secondary_business_category
  end
end
