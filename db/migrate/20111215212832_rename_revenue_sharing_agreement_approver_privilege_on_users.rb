class RenameRevenueSharingAgreementApproverPrivilegeOnUsers < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :users, :has_fee_sharing_agreement_approver_privilege, :boolean, :default => false
  end

  def self.down
    remove_column_using_tmp_table :users, :has_fee_sharing_agreement_approver_privilege
  end
end
