class ClickCount < ActiveRecord::Base
  belongs_to :clickable, :polymorphic => true
  belongs_to :publisher

  #
  # == Named Scopes
  #
  named_scope :since, lambda {|date|
    {
      :conditions => ["created_at >= ?", date],
      :order => 'created_at desc'
    }
  }
  
  named_scope :facebook, :conditions => { :mode => "facebook" }
  named_scope :twitter,  :conditions => { :mode => "twitter" }
  
  def self.record(clickable, publisher_id, mode = nil)
    time = Time.now.utc.beginning_of_day
    connection.execute %Q{
      INSERT INTO click_counts (clickable_type, clickable_id, publisher_id, created_at, updated_at, count, mode)
      VALUES ('#{clickable.class.name}', #{clickable.id}, #{publisher_id}, '#{time.to_formatted_s(:db)}', NOW(), 1, '#{mode}')
      ON DUPLICATE KEY UPDATE updated_at = NOW(), count = count + 1
    }
  end
end
