class CreateThirdPartyEvent < ActiveRecord::Migration
  def self.up
    create_table :third_party_events do |t|
      t.references :visitor, :polymorphic => true
      t.references :third_party, :polymorphic => true
      t.string :third_party_label
      t.references :target, :polymorphic => true
      t.string :action, :null => false
      t.string :url
      t.string :referral_url
      t.string :session_id, :null => false
      t.string :ip_address
      t.timestamps
    end
    create_table :third_party_event_purchases do |t|
      t.references :third_party_event
      t.decimal :price, :precision => 10, :scale => 2, :default => 0.0, :null => false
      t.integer :quantity, :null => false
      t.string  :product_id
      t.string  :transaction_id
      t.timestamps
    end
  end

  def self.down
    drop_table :third_party_events
    drop_table :third_party_event_purchases
  end
end
