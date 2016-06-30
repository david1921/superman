class PublisherZipCode < ActiveRecord::Base
  belongs_to :publisher
  validates_presence_of :publisher, :zip_code
  validates_uniqueness_of :zip_code, :scope => :publisher_id
  validate :publisher_belongs_to_a_group
  
  # The idea behind this model is to answer this question:
  # 
  # Given a zip code, which publisher in our publishing group
  # should I assign this subscriber (or consumer) to?
  #
  # Each publisher must be associated with a publishing group
  # otherwise we have no context for deciding which "set" of
  # publishers to search for a matching zip code.
  def publisher_belongs_to_a_group
    unless publisher.publishing_group.present?
      errors.add_to_base("publisher must be associated with a publishing group")
    end
  end
  
end
