class ManageablePublisher < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :publisher
  
  validates_presence_of :user_id, :publisher_id
  validates_uniqueness_of :publisher_id, :scope => :user_id
  validate :user_must_have_publishing_group_company
  validate :publisher_must_belong_to_user_publishing_group
  validate :user_must_not_be_an_admin
  
  protected
  
  def user_must_have_publishing_group_company
    unless user.try(:company).is_a?(PublishingGroup)
      errors.add(:user, "%{attribute} must have company_type PublishingGroup, but company_type is #{user.company.class}")
    end
  end
  
  def publisher_must_belong_to_user_publishing_group
    return unless user.try(:company).is_a?(PublishingGroup)
    unless user.company.publishers.exists?(:id => publisher_id)
      errors.add(:publisher_id, "%{attribute} must belong to publishing group '#{user.company.name}' (ID: #{user.company.id}), but it does not")
    end
  end
  
  def user_must_not_be_an_admin
    if user.try(:has_admin_privilege?)
      errors.add(:user, "%{attribute} must not be an admin")
    end
  end
  
end
