class ContactRequest < ActiveRecordWithoutTable
  include ContactRequests::Core

  @@attributes = :first_name, :last_name, :reason_for_request, :email, :message, :publisher, :email_subject_format
  attr_accessor *@@attributes

  validates_presence_of :first_name, :last_name, :email, :message
  validates_email :email, :allow_blank => true

end
