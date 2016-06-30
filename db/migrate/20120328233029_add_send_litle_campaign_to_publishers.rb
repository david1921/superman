class AddSendLitleCampaignToPublishers < ActiveRecord::Migration
  def self.up
    add_column :publishers, :send_litle_campaign, :boolean, :default => true
    execute "UPDATE publishers SET send_litle_campaign = false WHERE publishing_group_id in" + 
            "(SELECT id FROM publishing_groups WHERE send_litle_campaign = false)"
  end

  def self.down
    remove_column :publishers, :send_litle_campaign
  end
end
