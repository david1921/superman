class SilverpopBxAdds < ActiveRecord::Migration
  def self.up
    add_column :publishing_groups, :silverpop_database_identifier, :string
    add_column :publishing_groups, :consumer_after_update_strategy, :string
    add_column :publishing_groups, :silverpop_template_identifier, :string
    add_column :publishing_groups, :silverpop_seed_template_identifier, :string
    add_column :publishing_groups, :silverpop_account_time_zone, :string
    add_column :publishers, :silverpop_seed_database_identifier, :string
    add_column :publishers, :email_blast_day_of_week, :string
    add_column :publishers, :send_weekly_email_blast_to_seed_list, :boolean, :default => false
    add_column :publishers, :send_weekly_email_blast_to_contact_list, :boolean, :default => false
    add_column :publishers, :silverpop_seed_template_identifier, :string
    add_column :scheduled_mailings, :success_at, :datetime
    add_column :scheduled_mailings, :error_at, :datetime
    add_column :scheduled_mailings, :error_message, :string
    create_table :new_silverpop_recipients do |t|
      t.belongs_to :consumer
      t.string :silverpop_seed_database_identifier
      t.string :silverpop_database_identifier
      t.string :silverpop_list_identifier
      t.datetime :opted_out_of_silverpop_seed_database_at
      t.datetime :recipient_added_to_silverpop_database_at
      t.datetime :recipient_added_to_silverpop_list_at
      t.string :old_email
      t.datetime :old_email_removed_at
      t.datetime :success_at
      t.datetime :error_at
      t.string :error_message
      t.timestamps
    end
    create_table :silverpop_list_moves do |t|
      t.belongs_to :consumer
      t.belongs_to :old_publisher
      t.belongs_to :new_publisher
      t.string :old_list_identifier
      t.string :new_list_identifier
      t.datetime :removed_from_old_list_at
      t.datetime :added_to_new_list_at
      t.datetime :success_at
      t.datetime :error_at
      t.datetime :error_message
      t.timestamps
    end
    create_table :silverpop_contact_audit_runs do |t|
      t.belongs_to :publisher
      t.integer :number_of_contacts_audited
      t.datetime :started_at
      t.datetime :ended_at
      t.timestamps
    end
    create_table :silverpop_contact_audit_run_errors do |t|
      t.belongs_to :silverpop_contact_audit_run
      t.datetime :error_at
      t.text :error_details
    end
  end

  def self.down
    remove_column :publishing_groups, :silverpop_database_identifier
    remove_column :publishing_groups, :consumer_after_update_strategy
    remove_column :publishing_groups, :silverpop_template_identifier
    remove_column :publishing_groups, :silverpop_account_time_zone
    remove_column :publishing_groups, :silverpop_seed_template_identifier
    remove_column :publishers, :silverpop_seed_database_identifier
    remove_column :publishers, :email_blast_day_of_week
    remove_column :publishers, :send_weekly_email_blast_to_seed_list
    remove_column :publishers, :send_weekly_email_blast_to_contact_list
    remove_column :publishers, :silverpop_seed_template_identifier
    remove_column :scheduled_mailings, :success_at
    remove_column :scheduled_mailings, :error_at
    remove_column :scheduled_mailings, :error_message
    drop_table :new_silverpop_recipients
    drop_table :silverpop_list_moves
    drop_table :silverpop_contact_audit_runs
    drop_table :silverpop_contact_audit_run_errors
  end
end
