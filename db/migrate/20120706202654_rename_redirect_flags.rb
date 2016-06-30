class RenameRedirectFlags < ActiveRecord::Migration
  def self.up
    remove_column_using_tmp_table :publishing_groups, :enable_redirect_to_main_publisher
    remove_column_using_tmp_table :publishers, :enable_redirect_to_landing_if_deal_not_shown_on_landing_page
    remove_column_using_tmp_table :publishing_groups, :enable_redirect_to_local_deal
    add_column_using_tmp_table :publishing_groups, :enable_redirect_to_users_publisher, :boolean, :default => false
  end

  def self.down
    add_column_using_tmp_table :publishing_groups, :enable_redirect_to_main_publisher, :boolean, :default => false
    add_column_using_tmp_table :publishers, :enable_redirect_to_landing_if_deal_not_shown_on_landing_page, :boolean, :default => false
    add_column_using_tmp_table :publishing_groups, :enable_redirect_to_local_deal, :boolean, :default => false
    remove_column_using_tmp_table :publishing_groups, :enable_redirect_to_users_publisher
  end
end
