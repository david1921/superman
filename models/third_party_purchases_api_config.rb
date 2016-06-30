class ThirdPartyPurchasesApiConfig < ActiveRecord::Base
  belongs_to :user

  validates_presence_of :user
  validates_uniqueness_of :user_id
  validates_format_of :callback_url, :with => URI.regexp(['https']), :message => '%{attribute} must be an https url', :allow_nil => true

  named_scope :with_complete_callback_config, :conditions => "callback_url IS NOT NULL AND callback_username IS NOT NULL AND callback_password IS NOT NULL"
end
