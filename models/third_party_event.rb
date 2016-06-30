class ThirdPartyEvent < ActiveRecord::Base
  VALID_ACTIONS = %w{lightbox lightbox-submit redirect landing purchase} 

  belongs_to :visitor, :polymorphic => true
  belongs_to :third_party, :polymorphic => true
  belongs_to :target, :polymorphic => true
  has_many :purchases, :class_name => "ThirdPartyEventPurchases"

  before_validation_on_create :standardize_action
  before_validation_on_create :set_visitor_via_session_id, :set_third_party_via_session_id, :set_target_via_session_id
   
  validates_presence_of :action, :session_id
  validates_inclusion_of :action, :in => VALID_ACTIONS
    
  named_scope :purchases, :conditions => "action = 'purchase'"
  named_scope :landing, :conditions => "action = 'landing'"

  def redirect?
    (self.action == 'redirect')
  end

  def landing?
    (self.action == 'landing')
  end
  
  def purchase?
    (self.action == 'purchase')
  end
  
  def set_visitor_via_session_id
    self.visitor ||= @session.try(:visitor)
  end
  
  def set_third_party_via_session_id
    self.visitor ||= @session.try(:third_party)
  end

  def set_target_via_session_id
    self.visitor ||= @session.try(:target)
  end

  def session
    @session ||= ThirdPartyEvent.find_by_session_id(self.session_id)
  end
  
  protected
  def standardize_action
    self.action = self.action.try(:downcase)
  end
   
end 