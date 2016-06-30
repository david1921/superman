class CreateCyberSourceCredentials < ActiveRecord::Migration
  def self.up
    create_table :cyber_source_credentials do |t|
      t.string :label
      t.string :merchant_id
      t.string :encrypted_shared_secret
      t.string :encrypted_serial_number
      t.string :soap_username
      t.string :encrypted_soap_password
      t.datetime :started_at
      t.datetime :retired_at
    end
  end

  def self.down
    drop_table :cyber_source_credentials
  end
end
