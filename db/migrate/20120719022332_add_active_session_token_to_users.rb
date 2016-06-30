class AddActiveSessionTokenToUsers < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :users, :active_session_token, :string
  end

  def self.down
    remove_column_using_tmp_table :users, :active_session_token
  end
end
