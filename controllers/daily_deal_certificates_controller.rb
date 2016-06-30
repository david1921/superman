class DailyDealCertificatesController < ApplicationController
  include Publishers::Themes
  include CertificatesIvr
  include Api

  before_filter :user_required, :except => [:find, :api_redeem, :ivr_validate, :ivr_redeem, :mark_used, :mark_unused, :redeemable]
  before_filter :set_daily_deal_certificate_from_serial_number, :except => [:mark_used, :mark_unused, :validate]
  before_filter :set_daily_deal_certificate_from_id, :only => [:mark_used, :mark_unused]
  before_filter :admin_or_consumer_for_certificate_publisher_required, :only => [:mark_used, :mark_unused]
  before_filter :render_404_unless_admin_or_current_consumer_owns_certificate, :only => [:mark_used, :mark_unused]
  before_filter :check_and_set_api_version_header_for_json_requests, :only => [:find, :api_redeem]
  before_filter :ensure_user_for_json_request, :only => [:find, :api_redeem]
  before_filter :set_daily_deal_certificate, :except => [:redeemable, :validate]
  before_filter :set_daily_deal_purchase, :only => [:redeemable]
  before_filter :admin_or_consumer_for_purchase_publisher_required, :only => [:redeemable]
  
  ssl_allowed :mark_used, :mark_unused, :find, :validate, :redeem, :api_redeem, :ivr_validate, :ivr_redeem, :redeemable
  
  protect_from_forgery :except => [:ivr_validate, :ivr_redeem, :api_redeem]
  
  layout "application"
  
  def find
    @daily_deal_certificate = nil unless current_user.can_observe?(@daily_deal_certificate.try(:advertiser))
    respond_to do |format|
      format.json do
        render :layout => false
      end
    end
  end
  
  def redeemable
    @daily_deal_certificates = @daily_deal_purchase.daily_deal_certificates.not_expired.redeemable
    @publisher = @daily_deal_purchase.publisher
    render with_theme(:layout => "daily_deal_certificates")
  end
  
  def validate
    @daily_deal_certificate = DailyDealCertificate.find_by_serial_number(@serial_number) if @serial_number.present?

    flash[:notice] = nil
    add_crumb "Validate Certificate", validate_daily_deal_certificates_path
    
    if @daily_deal_certificate
      if @daily_deal_certificate.redeemed?
        @errors = "Serial number #{@daily_deal_certificate.serial_number} has already been REDEEMED"
        @daily_deal_certificate = false
      else
        @status = "Serial number #{@daily_deal_certificate.serial_number} is VALID"
      end
    elsif @serial_number.present?
      @errors = "Serial number #{@serial_number} is NOT VALID"
    else
      flash[:notice] = "Enter a certificate serial number to be validated"
    end
  end
  
  def redeem
    if @daily_deal_certificate
      @daily_deal_certificate.redeem!
      flash[:notice] = "Certificate #{@daily_deal_certificate.serial_number} marked as redeemed#{at_location(@daily_deal_certificate)}"
      @daily_deal_certificate = false
    else
      flash[:warn] = "Could not locate certificate #{@serial_number}"
    end
    flash[:notice] ||= "Enter a certificate serial number to be validated"
    render :action => :validate
  end
  #
  # A separate action for JSON requests, which send authentication
  # data in the request body and so do not involve CSRF protection.
  #
  def api_redeem
    @daily_deal_certificate = DailyDealCertificate.find_by_id(params[:id])
    @daily_deal_certificate = nil unless current_user.can_observe?(@daily_deal_certificate.try(:advertiser))
    @daily_deal_certificate.try :redeem!
    respond_to do |format|
      format.json do
        render(@daily_deal_certificate ? { :json => {} } : { :nothing => true, :status => :not_found })
      end
    end
  end
  
  def mark_used
    @daily_deal_certificate.mark_used_by_user!
    flash[:notice] = translate_with_theme(:certificate_marked_as_used_message,
                                          :serial_number => @daily_deal_certificate.serial_number,
                                          :scope => :daily_deal_certificates_controller)
    redirect_to :back
  end

  def mark_unused
    @daily_deal_certificate.mark_unused_by_user!
    flash[:notice] = translate_with_theme(:certificate_marked_as_unused_message,
                                          :serial_number => @daily_deal_certificate.serial_number,
                                          :scope => :daily_deal_certificates_controller)
    redirect_to :back
  end
  
  private
  
  def set_daily_deal_certificate
    @daily_deal_certificate = DailyDealCertificate.validatable.find_by_serial_number(@serial_number) if @serial_number.present?
  end
  
  def admin_or_consumer_for_certificate_publisher_required
    admin? || consumer_login_required(@daily_deal_certificate.publisher)
  end
  
  def render_404_unless_admin_or_current_consumer_owns_certificate
    render_404 unless admin? || @daily_deal_certificate.consumer == current_consumer
  end
  
  def set_daily_deal_certificate_from_serial_number
    @daily_deal_certificate = DailyDealCertificate.captured.find_by_serial_number(@serial_number) if @serial_number.present?
  end
  
  def set_daily_deal_certificate_from_id
    @daily_deal_certificate = DailyDealCertificate.captured.find(params[:id])
  end
  
  def set_daily_deal_purchase
    @daily_deal_purchase = DailyDealPurchase.find_by_uuid!(params[:daily_deal_purchase_id])
  end
  
  def admin_or_consumer_for_purchase_publisher_required
    admin? || consumer_login_required(@daily_deal_purchase.publisher)
  end
  
  def at_location(daily_deal_certificate)
    if daily_deal_certificate.daily_deal.location_required? && daily_deal_certificate.store.present?
      " at #{daily_deal_certificate.store.summary}" 
    end
  end

end
