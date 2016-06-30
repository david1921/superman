class SubscriberReferrerCode < ActiveRecord::Base
    
  #
  # == Validations
  #               
  validates_presence_of   :code
  validates_uniqueness_of :code
  
  #
  # == Callbacks
  #
  before_validation_on_create :generate_code_unless_present
  
  
  private
  
  def generate_code_unless_present
    self.code ||= UUIDTools::UUID.random_create.hexdigest[0..6]
  end
  
end
