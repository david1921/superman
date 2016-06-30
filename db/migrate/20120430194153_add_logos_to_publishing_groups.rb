class AddLogosToPublishingGroups < ActiveRecord::Migration
  def self.up
    with_tmp_table :publishing_groups do |tmp_table_name|
      add_column tmp_table_name, :logo_file_name, :string
      add_column tmp_table_name, :logo_content_type, :string
      add_column tmp_table_name, :logo_file_size, :integer
      add_column tmp_table_name, :logo_updated_at, :datetime
    end
  end

  def self.down
    with_tmp_table :publishing_groups do |tmp_table_name|
      remove_column tmp_table_name, :logo_file_name, :string
      remove_column tmp_table_name, :logo_content_type, :string
      remove_column tmp_table_name, :logo_file_size, :integer
      remove_column tmp_table_name, :logo_updated_at, :datetime
    end
  end
end
