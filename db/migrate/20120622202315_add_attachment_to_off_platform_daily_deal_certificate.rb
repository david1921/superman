class AddAttachmentToOffPlatformDailyDealCertificate < ActiveRecord::Migration
    def self.up
      add_column :off_platform_daily_deal_certificates, :voucher_pdf_file_name,    :string
      add_column :off_platform_daily_deal_certificates, :voucher_pdf_content_type, :string
      add_column :off_platform_daily_deal_certificates, :voucher_pdf_file_size,    :integer
      add_column :off_platform_daily_deal_certificates, :voucher_pdf_updated_at,   :datetime
    end

    def self.down
      remove_column :off_platform_daily_deal_certificates, :voucher_pdf_file_name
      remove_column :off_platform_daily_deal_certificates, :voucher_pdf_content_type
      remove_column :off_platform_daily_deal_certificates, :voucher_pdf_file_size
      remove_column :off_platform_daily_deal_certificates, :voucher_pdf_updated_at
    end
end
