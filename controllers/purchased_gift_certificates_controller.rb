class PurchasedGiftCertificatesController < ApplicationController
  include CertificatesIvr

  before_filter :user_required, :except => [:ivr_validate, :ivr_redeem]
  before_filter :set_purchased_gift_certificate

  protect_from_forgery :except => [:ivr_validate, :ivr_redeem]
  
  def index
    respond_to do |format| 
      format.pdf do
        purchased_gift_certificates = PurchasedGiftCertificate.completed(nil).find(params[:id])
        Publisher.observable_by(current_user).find(purchased_gift_certificates.map(&:publisher).map(&:id))
        filename = case purchased_gift_certificates.size
                   when 1
                     "Deal Certificate #{purchased_gift_certificates.first.serial_number}.pdf"
                   else
                     "Deal Certificates.pdf"
                   end
        send_data PurchasedGiftCertificate.to_pdf(purchased_gift_certificates), :filename => filename, :type => :pdf
      end
    end 
  end
  
  def validate
    flash[:notice] = nil
    add_crumb "Validate Deal Certificate", validate_purchased_gift_certificates_path
    
    if @purchased_gift_certificate
      if @purchased_gift_certificate.redeemable?
        @status = "Serial number #{@purchased_gift_certificate.serial_number} is VALID"
      elsif @purchased_gift_certificate.redeemed?
        @errors = "#{@purchased_gift_certificate.serial_number} is INVALID. Reason: it was already redeemed."
        @purchased_gift_certificate = nil
      else
        @errors = "#{@purchased_gift_certificate.serial_number} is INVALID. It has a status of #{@purchased_gift_certificate.status}."
        @purchased_gift_certificate = nil
      end
    elsif @serial_number.present?
      @errors = "Serial number #{@serial_number} is NOT VALID"
    else
      flash[:notice] = "Enter a deal certificate serial number to be validated"
    end
  end
  
  def redeem
    if @purchased_gift_certificate
      @purchased_gift_certificate.redeem!
      flash[:notice] = "Deal certificate #{@purchased_gift_certificate.serial_number} marked as redeemed"
      @purchased_gift_certificate = nil
    else
      flash[:warn] = "Could not locate deal certificate #{@serial_number}"
    end
    flash[:notice] ||= "Enter a deal certificate serial number to be validated"
    render :action => :validate
  end
  
  private
  
  def set_purchased_gift_certificate
    @purchased_gift_certificate = PurchasedGiftCertificate.find_by_serial_number(@serial_number) if @serial_number.present?
  end
  
end
