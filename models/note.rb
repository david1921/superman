class Note < ActiveRecord::Base

	#
	# === Associations
	#
  belongs_to :notable, :polymorphic => true
  belongs_to :user

  #
  # === Validations
  #
  validates_presence_of :notable, :user, :text
  validates_each :external_url, :allow_blank => true do |record, attr, value|
    uri = URI.parse(value) rescue nil
    record.errors.add attr, '{{attribute}} must be an HTTP or HTTPS URL' unless uri && (uri.scheme == "http" || uri.scheme == "https")
  end  

  #
  # === Attachment
  #
  has_attached_file :attachment,
                    :bucket           => "attachments.notes.analoganalytics.com",
                    :s3_host_alias    => "attachments.notes.analoganalytics.com",
                    :path             => ":rails_env_fallback/:id/:style.:extension"

  #
  # === Named Scopes
  #
  named_scope :descending_by_updated_at, lambda {
  	{
  		:order => "updated_at desc"
  	}
  }
end
