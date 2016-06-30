class SilverBxChanges < ActiveRecord::Migration
  def self.up
    rename_column :publishers, :silverpop_contact_list_identifier, :silverpop_list_identifier
    rename_column :publishers, :silverpop_email_template_identifier, :silverpop_template_identifier
    rename_column :daily_deals, :enable_email_blast, :enable_daily_email_blast
  end

  def self.down
    rename_column :publishers, :silverpop_list_identifier, :silverpop_contact_list_identifier
    rename_column :publishers, :silverpop_template_identifier, :silverpop_email_template_identifier
    rename_column :daily_deals, :enable_daily_email_blast, :enable_email_blast
  end
end
