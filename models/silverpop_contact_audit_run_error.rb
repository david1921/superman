class SilverpopContactAuditRunError < ActiveRecord::Base
  belongs_to :silverpop_contact_audit_run
  validates_presence_of :silverpop_contact_audit_run
end
