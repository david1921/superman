class AddShoppingMallFlagToPublisher < ActiveRecord::Migration

  def self.up
    add_column :publishers, :shopping_mall, :boolean, :default => false
  end

  def self.down
    remove_column :publishers, :shopping_mall
  end

end
