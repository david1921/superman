class CreateRecipients < ActiveRecord::Migration
  def self.up
    create_table :recipients do |t|
	    t.integer  "country_id"
	    t.string   "address_line_1"
	    t.string   "address_line_2"
	    t.string   "city"
	    t.string   "state"
	    t.string   "zip"
	    t.string   "phone_number"
	    t.float    "longitude"
	    t.float    "latitude"
	    t.string   "region"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	    t.string   "name"
	    t.string   "addressable_type"
	    t.string   "addressable_id"
      t.timestamps
    end
  end

  def self.down
    drop_table :recipients
  end
end
