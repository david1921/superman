class Syndication::Agreement < ActiveRecord::Base
  validates_presence_of :title
  validates_presence_of :contact_name
  validates_presence_of :company_name
  validates_presence_of :telephone_number
  validates_presence_of :email
  validates_acceptance_of :business_terms
  validates_acceptance_of :syndication_terms
  
  before_create :set_serial_number
  after_create :deliver_email

  attr_accessor :business_terms
  attr_accessor :syndication_terms
  
  def deliver_email
    Syndication::AgreementsMailer.deliver_confirmation self
  end
  
  def set_serial_number
    self.serial_number = SecureRandom.random_number(10_000_000)
  end
end
