class CreateNotes < ActiveRecord::Migration
  def self.up
    create_table :notes do |t|
      t.text :text
      t.integer :user_id
      t.string :notable_type
      t.integer :notable_id

      t.timestamps
    end
  end

  def self.down
    drop_table :notes
  end
end
