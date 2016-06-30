class BarCode < ActiveRecord::Base
  belongs_to :bar_codeable, :polymorphic => true
  
  validates_presence_of :code
  
  named_scope :unassigned, :conditions => "NOT assigned"

  acts_as_list :scope => :bar_codeable_id
end
