class CreateAddresses < ActiveRecord::Migration
  def self.up
    create_table :addresses do |t|
      t.belongs_to :country
      t.string   "address_line_1"
      t.string   "address_line_2"
      t.string   "city"
      t.string   "state"
      t.string   "zip"
      t.string   "phone_number"
      t.float    "longitude"
      t.float    "latitude"
      t.string   "region"
      t.timestamps
    end
  end

  def self.down
    drop_table :addresses
  end
end
