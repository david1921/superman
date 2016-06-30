class SupportContactRequest < ContactRequest
  attr_accessor :reason_for_request

  validates_presence_of :reason_for_request
end
