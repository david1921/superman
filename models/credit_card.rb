class CreditCard < ActiveRecord::Base
  belongs_to :consumer
  
  attr_accessor :bin
  
  before_validation :set_hexdigest
  
  validates_presence_of :consumer
  validates_presence_of :card_type
  validates_presence_of :hexdigest
  validates_uniqueness_of :token, :scope => :consumer_id
  validates_format_of :bin, :with => /\A\d+\z/
  validates_format_of :last_4, :with => /\A\d{4}\z/
  
  before_destroy :delete_from_vault
  
  def self.find_by_consumer_id_and_bin_and_last_4(consumer_id, bin, last_4)
    return nil unless [consumer_id, bin, last_4].all?(&:present?)
    first(:conditions => { :consumer_id => consumer_id, :hexdigest => hexdigest(consumer_id, bin, last_4) })
  end
  
  def descriptor
    "#{card_type} ending in #{last_4}"
  end

  def expiration_date=(expiration_date)
    date = expiration_date.split("/")
    write_attribute :expiration_date, Date.new(date[1].to_i, date[0].to_i, 1)
  end

  private
  
  def self.hexdigest(consumer_id, bin, last_4)
    Digest::SHA1.hexdigest("#{consumer_id}-#{bin}-#{last_4}")
  end
  
  def set_hexdigest
    self.hexdigest = self.class.hexdigest(consumer_id, @bin, last_4)
  end
  
  def delete_from_vault
    consumer.publisher.find_braintree_credentials!
    Braintree::CreditCard.delete(token)
  rescue
    logger.warn "Failed to delete card #{id} with token '#{token}' from vault"
    false
  end
end
