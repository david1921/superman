class AddExternalUrlToNotes < ActiveRecord::Migration
  def self.up
  	add_column_using_tmp_table :notes, :external_url, :text
  end

  def self.down
  	remove_column_using_tmp_table :notes, :external_url
  end
end
