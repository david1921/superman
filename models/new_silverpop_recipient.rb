class NewSilverpopRecipient < ActiveRecord::Base
  include NewSilverpopRecipients::AddRecipientToSilverpop
  belongs_to :consumer
  validates_presence_of :consumer
end
