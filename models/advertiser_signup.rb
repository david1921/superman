class AdvertiserSignup < ActiveRecord::Base
  belongs_to :advertiser
  belongs_to :publisher
  belongs_to :user

  validates_presence_of :advertiser, :publisher, :user
  
  after_create :deliver_notification
  
  attr_accessor :password, :password_confirmation, :advertiser_name
  
  def deliver_notification
    AdvertiserSignupMailer.deliver_notification user
  end
end
