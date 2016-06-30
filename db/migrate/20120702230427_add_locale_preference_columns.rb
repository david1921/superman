class AddLocalePreferenceColumns < ActiveRecord::Migration
  def self.up
  	add_column_using_tmp_table :publishing_groups, :enabled_locales, :string, :default => [].to_yaml
  	add_column_using_tmp_table :publishers, :enabled_locales, :string, :default => [].to_yaml
  end

  def self.down
  	remove_column_using_tmp_table :publishing_groups, :enabled_locales
  	remove_column_using_tmp_table :publishers, :enabled_locales
  end
end
