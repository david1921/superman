class SalesContactRequest < ContactRequest
  attr_accessor :title, :phone_number, :company, :website, :type, :city, :state, :zip_code

  validates_presence_of :company
end

