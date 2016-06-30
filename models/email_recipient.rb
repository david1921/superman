class EmailRecipient < ActiveRecord::Base
  RANDOM_CODE_ALPHABET = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
  
  attr_reader :email_allowed_before
  
  before_validation :assign_random_code

  validates_presence_of :email_address
  validates_presence_of :random_code

  def self.address_opted_out?(email_address)
    email_recipient = EmailRecipient.find_by_email_address(email_address)
    email_recipient && !email_recipient.email_allowed
  end
  
  def self.random_code_for(email_address)
    email_recipient = EmailRecipient.find_or_create_by_email_address(email_address)
    email_recipient.random_code
  end
  
  def opt_out
    @email_allowed_before = email_allowed
    update_attributes! :email_allowed => false
  end
  
  def trigger_opt_in
    @email_allowed_before = email_allowed
    unless email_allowed
      #
      # Invalidate previous activation link by assigning a new randome code.
      #
      self.random_code = nil
      save(true)
      OptingMailer.deliver_email_opt_in_instructions(self)
    end
  end

  def opt_in
    @email_allowed_before = email_allowed
    update_attributes! :email_allowed => true
  end
  
  private
  
  def assign_random_code
    self.random_code = Array.new(16) { RANDOM_CODE_ALPHABET[rand(RANDOM_CODE_ALPHABET.size)] }.join if self.random_code.blank?
  end
end
