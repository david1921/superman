class UserCompany < ActiveRecord::Base
  validates_presence_of :company_id, :company_type
  validates_uniqueness_of :user_id, :scope => [:company_id, :company_type], :allow_blank => true
  
  belongs_to :user
  belongs_to :company, :polymorphic => true
  
  validate :company_has_not_changed_for_non_admin_user
  validate :non_admin_user_can_have_only_one_company, :on => :create
  
  def non_admin_user_can_have_only_one_company
    unless new_record?
      raise "non_admin_user_can_have_only_one_company validation unexpectedly called on existing record"
    end
    
    return if !user || user.has_admin_privilege?
    
    if UserCompany.exists?(:user_id => user.id)
      errors.add_to_base("Non-admin users can be associated to at most one company")
    end
  end
  
  def company_has_not_changed_for_non_admin_user
    return if new_record? || user.has_admin_privilege?
    
    if (company_type_was && company_type_was != company_type) || (company_id_was && company_id_was != company_id)
      errors.add(:company_id, "%{attribute} cannot change")
    end
  end

  
end