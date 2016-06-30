class AddAdvertiserOwners < ActiveRecord::Migration
  def self.up
    create_table :advertiser_owners do |t|
      t.belongs_to  :advertiser
      t.string      :first_name 
      t.string      :last_name
      t.string      :home_postal_code
      t.string      :home_address
      t.timestamps
    end
    add_index :advertiser_owners, :advertiser_id
  end

  def self.down
    drop_table :advertiser_owners
  end
end
