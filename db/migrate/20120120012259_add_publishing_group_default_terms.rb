class AddPublishingGroupDefaultTerms < ActiveRecord::Migration
  def self.up
  	add_column :publishing_groups, :terms_default, :text, :null => false, :default => nil
  end

  def self.down
  	remove_column :publishing_groups, :terms_default
  end
end
