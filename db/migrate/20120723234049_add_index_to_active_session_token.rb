class AddIndexToActiveSessionToken < ActiveRecord::Migration
  def self.up
    add_index_using_tmp_table :users, :active_session_token
  end

  def self.down
    remove_index_using_tmp_table :users, :active_session_token
  end
end
