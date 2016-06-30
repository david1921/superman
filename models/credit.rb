class Credit < ActiveRecord::Base
  belongs_to :consumer
  belongs_to :origin, :polymorphic => true
  
  validates_numericality_of :amount, :greater_than => 0.00, :allow_nil => false
  validates_immutability_of :amount
  
  def amount=(value)
    raise "Credit amount cannot be changed" unless read_attribute(:amount).nil?
    write_attribute(:amount, value)
  end
end
