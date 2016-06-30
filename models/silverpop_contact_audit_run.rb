class SilverpopContactAuditRun < ActiveRecord::Base
  belongs_to :publisher
  has_many :silverpop_contact_audit_run_errors
  validates_presence_of :publisher
end
