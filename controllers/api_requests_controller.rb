class ApiRequestsController < ApplicationController
  before_filter :perform_http_basic_authentication
  before_filter :check_and_set_api_version_headers
  before_filter :set_publisher, :except => [:root, :advertiser_web_coupons_service]
  before_filter :set_service_name
  
  skip_before_filter :verify_authenticity_token
  
  ssl_allowed   :root, :sb_root, :txt_service, :txt_service, :call_service, :email_service, :report_service,
                :web_coupon_service, :sb_web_coupons_service, :ensure_api_version, :advertiser_web_coupons_service
  
  def root
    @api_services = {
         "TXT" => api_txt_service_url,
        "Call" => api_call_service_url,
       "Email" => api_email_service_url,
      "Report" => api_report_service_url,
      "WebCoupon" => api_web_coupon_service_url,
      "TxtCoupon" => api_txt_coupon_service_url,
      "AdvertiserWebCoupons" => api_advertiser_web_coupons_service_url
    }
  end
  
  def sb_root
    @api_services = {
      "WebCoupons" => sb_api_web_coupons_service_url
    }
  end
  
  def txt_service
    attributes = params.slice(:mobile_number, :message, :report_group)
    @api_request = @publisher.txt_api_requests.build(attributes)
    @error = @api_request.error unless @api_request.save
    render_unless_error :status => :created
  end

  def call_service
    attributes = params.slice(:consumer_phone_number, :merchant_phone_number, :report_group)
    @api_request = @publisher.call_api_requests.build(attributes)
    @error = @api_request.error unless @api_request.save
    render_unless_error :status => :created
  end

  def email_service
    attributes = params.slice(:email_subject, :destination_email_address, :text_plain_content, :text_html_content, :report_group)
    @api_request = @publisher.email_api_requests.build(attributes)
    @error = @api_request.error unless @api_request.save
    render_unless_error :status => :created
  end
  
  def report_service
    unless api_version?( "1.2.0" )
      attributes = params.slice(:dates_begin, :dates_end, :report_group)
      @api_request = @publisher.report_api_requests.build(attributes)
      @error = @api_request.error unless @api_request.save
      template = "1.0.0" == @api_version ? "api_requests/report_service_1_0_0" : "api_requests/report_service_1_1_0"
      render_unless_error :template => template, :status => :ok
    else
      attributes = params.slice(:dates_begin, :dates_end, :web_coupon_ids, :txt_coupon_ids)
      @api_request = @publisher.report_api_requests.build(attributes)
      @error = @api_request.error unless @api_request.valid? && @api_request.error.blank?
      render_unless_error :template => 'api_requests/report_service_1_2_0', :status => :ok
    end
  end
  
  def web_coupon_service
    if ensure_api_version("1.2.0")
      attributes = params.slice(
        :advertiser_name,
        :advertiser_client_id,
        :advertiser_location_id,
        :advertiser_coupon_clipping_modes,
        :advertiser_website_url,
        :advertiser_logo,
        :advertiser_industry_codes,
        :advertiser_store_address_line_1,
        :advertiser_store_address_line_2,
        :advertiser_store_city,
        :advertiser_store_state,
        :advertiser_store_zip,
        :advertiser_store_phone_number,
        :web_coupon_label,
        :web_coupon_message,
        :web_coupon_terms,
        :web_coupon_txt_message,
        :web_coupon_image,
        :web_coupon_show_on,
        :web_coupon_expires_on,
        :web_coupon_featured,
        :_method
      )
      @api_request = @publisher.web_coupon_api_requests.build(attributes)
      @error = @api_request.error unless @api_request.save
      render_unless_error :status => :created
    end
  end 
  
  def advertiser_web_coupons_service
    @advertiser = Advertiser.find_by_listing("#{params[:client_id]}-#{params[:location_id]}")
    if @advertiser
      @publisher  = @advertiser.publisher
      @offers     = @advertiser.offers.active
      @categories = Category.all_with_offers_count_for_publisher({:publisher => @publisher})
    else
      raise ActiveRecord::RecordNotFound.new("#{params[:client_id]}-#{params[:location_id]}")
    end    
  end
  
  def sb_web_coupons_service
    if ensure_api_version("1.0.0")
      params[:id].present? ? sb_web_coupons_show : sb_web_coupons_index
    end
  end
  
  def txt_coupon_service
    if ensure_api_version("1.2.0")
      attributes = params.slice(
        :advertiser_name,
        :advertiser_client_id,
        :advertiser_location_id,
        :advertiser_website_url,
        :advertiser_industry_codes,
        :advertiser_store_address_line_1,
        :advertiser_store_address_line_2,
        :advertiser_store_city,
        :advertiser_store_state,
        :advertiser_store_zip,
        :advertiser_store_phone_number,
        :txt_coupon_label,
        :txt_coupon_keyword,
        :txt_coupon_message,
        :txt_coupon_appears_on,
        :txt_coupon_expires_on,
        :_method
      )
      @api_request = @publisher.txt_coupon_api_requests.build(attributes)
      @error = @api_request.error unless @api_request.save
      render_unless_error :status => :created            
    end
  end
  
  private
  
  def ensure_api_version( version )
    unless api_version?( version )
      @api_version = version
      render :action => :invalid_api_version, :status => :not_acceptable 
      return false
    else
      return true
    end
  end
  
  def api_version?( version )
    version == @api_version
  end
  
  def check_and_set_api_version_headers
    @api_version = request.headers['API-Version']
    unless %w{ 1.0.0 1.1.0 1.2.0 }.include?(@api_version)
      @api_version = "1.2.0"
      render :action => :invalid_api_version, :status => :not_acceptable
    end
    response.headers['API-Version'] = @api_version
  end
  
  def set_publisher
    @publisher = Publisher.manageable_by(@user).find_by_label(params[:publisher_label]) if params[:publisher_label].present?
    render_forbidden unless @publisher
  end
  
  def render_unless_error(options)
    render @error ? { :template => "api_requests/error", :status => :bad_request} : options
  end
  
  def set_service_name
    @service_name = params[:action].to_s.sub(/_service/, "")
  end
  
  def render_forbidden
    render :nothing => true, :status => :forbidden
  end
  
  def sb_web_coupons_index
    @publisher = Publisher.manageable_by(@user).find_by_label(params[:publisher_label]) if params[:publisher_label].present?
    if @publisher
      @request = WebCouponsRequest::Index.new(:publisher => @publisher, :timestamp => params[:timestamp])
      render :template => "sb_web_coupons_index"
    else
      render_forbidden
    end
  end
  
  def sb_web_coupons_show
    @request = WebCouponsRequest::Show.new(:user => @user, :ids => params[:id])
    render :template => "sb_web_coupons_show"
  rescue ActiveRecord::RecordNotFound
    render :nothing => true, :status => :not_found
  end
end
