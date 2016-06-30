class PublisherMembershipCode < ActiveRecord::Base
  belongs_to :publisher

  validates_presence_of :code
  validates_presence_of :publisher
  validate :code_unique_within_publishing_group

  private

  def code_unique_within_publishing_group
    return if code.blank?

    found_code = publisher.publishing_group.publisher_membership_codes.find_by_code(code)

    if found_code && found_code.id != self.id
      errors.add(:code, "%{attribute} must be unique within the publishing group")
    end
  end
end
