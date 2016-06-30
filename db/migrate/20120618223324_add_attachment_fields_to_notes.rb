class AddAttachmentFieldsToNotes < ActiveRecord::Migration
  def self.up
		add_column_using_tmp_table :notes, :attachment_content_type, :string
		add_column_using_tmp_table :notes, :attachment_file_name, :string
		add_column_using_tmp_table :notes, :attachment_file_size, :integer
		add_column_using_tmp_table :notes, :attachment_updated_at, :datetime
  end

  def self.down
		remove_column_using_tmp_table :notes, :attachment_content_type
		remove_column_using_tmp_table :notes, :attachment_file_name
		remove_column_using_tmp_table :notes, :attachment_file_size
		remove_column_using_tmp_table :notes, :attachment_updated_at
  end
end
