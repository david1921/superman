class PushNotificationDevice < ActiveRecord::Base
  belongs_to :publisher
  
  validates_presence_of :token
  validates_uniqueness_of :token, :scope => :publisher_id
  
  named_scope :by_tokens, lambda {|tokens|
    {
      :conditions => ["token in (?)", tokens]
    }
  }
  
  class << self
   
    def publishers_with_deals_today
      publishers = Publisher.find(:all, :conditions => "id IN (SELECT publisher_id FROM push_notification_devices)")
      publishers.reject { |p| !p.daily_deals.today }
    end
    
    def enroll(publisher, token)
      token = normalized_token(token)
      publisher.push_notification_devices.find_or_create_by_token(token).tap do |object|
        object.save
      end
    end

    def reject(publisher, token)
      token = normalized_token(token)
      publisher.push_notification_devices.find_by_token(token).tap do |object|
        object.destroy if object
      end
    end
      
    private
  
    def normalized_token(value)
      value.gsub(/\s-/, '').upcase
    end
    
  end
  
  def send_notification!(notification)
    with_pem_file(pem_filename_for_publisher_or_group) do
      APNS.send_notification(token, notification) if send_apns_notifications?
    end
  end
  
  def with_pem_file(pem_filename)
    raise "must be called with a block" unless block_given?
    orig_pem_file = APNS.pem
    APNS.pem = pem_filename
    yield
  ensure
    APNS.pem = orig_pem_file
  end
  
  def pem_filename_for_publisher_or_group
    publisher_pem_filename = Rails.root.join("config", "apns", "#{publisher.label}.pem")
    return publisher_pem_filename if File.exists?(publisher_pem_filename)
    
    if publisher.publishing_group.present?
      publishing_group_pem_filename = Rails.root.join("config", "apns", "#{publisher.publishing_group.label}.pem")
      return publishing_group_pem_filename if File.exists?(publishing_group_pem_filename)
    end
    
    raise "couldn't find APNS pem file for publisher '#{publisher.label}'"
  end
  
  private
  
  def send_apns_notifications?
    Rails.env.production? || Rails.env.staging?
  end
  
end
