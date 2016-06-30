class Api2Controller < ApplicationController

  before_filter :perform_http_basic_authentication, :except => [:web_coupons_count_impressions]
  before_filter :check_and_set_api_version_headers, :except => [:web_coupons_count_impressions]
  
  skip_before_filter :verify_authenticity_token
  
  ssl_allowed :root, :web_coupons, :web_coupons_categories, :web_coupons_count_impressions
  
  layout nil
  
  def root
    @api_services = {
      "WebCoupons" => api2_web_coupons_url
    }
  end
  
  def web_coupons
    if ensure_api_version("2.0.0")
      params.has_key?(:id) ? web_coupons_show : web_coupons_index
    end
  end
  
  def web_coupons_categories
    if ensure_api_version("2.0.0")
      logger.info @user.inspect
      if params[:publisher_label].present? && (@publisher = Publisher.manageable_by(@user).find_by_label(params[:publisher_label]))
        @request = Api2::WebCouponsRequest::Categories.new(:publisher => @publisher)
        if @request.error
          render :action => "error"
        else
          render
        end
      else
        render :nothing => true, :status => :forbidden
      end
    end
  end
  
  def web_coupons_count_impressions
    begin
      raise ArgumentError, "Missing required parameter: ids" unless params[:ids].present?
      raise ArgumentError, "Missing required parameter: publisher_label" unless params[:publisher_label].present?
    rescue ArgumentError => e
      render :text => e.message, :status => :not_acceptable
      return
    end

   unless (publisher = Publisher.find_by_label(params[:publisher_label]))
      render :text => "Unknown publisher: #{params[:publisher_label]}", :status => :not_found
    else
      offer_ids = params[:ids].split(",").map(&:to_i)
      processed_offer_ids = Set.new
      offers = publisher.offers.find(:all, :conditions => { :id => offer_ids })

      Api2Controller.benchmark "Api2Controller#web_coupons_count_impressions" do
        offers.each do |offer|
          offer.record_impression(publisher.id)
          processed_offer_ids << offer.id
        end
      end
      
      unprocessed_offer_ids = (Set.new(offer_ids) - processed_offer_ids).to_a
      if unprocessed_offer_ids.present?
        render :text => "Unknown offer IDs: #{format_unprocessed_ids(unprocessed_offer_ids)}", :status => :not_found
        return
      end
      render :nothing => true, :status => :ok
    end
  end

  def syndicated_web_coupons
    if ensure_api_version("2.0.0")
      if @user.allow_offer_syndication_access
        @request = Api2::WebCouponsRequest::SyndicatedIndex.new(:timestamp_min => params[:timestamp_min])
        if @request.error
          render :action => "error"
        else
          render :action => "web_coupons_index"
        end
      else
        render :nothing => true, :status => :forbidden
      end
    end
  end
  
  private
  
  def format_unprocessed_ids(unprocessed_ids)
    unprocessed_ids.sort.map { |o| "#{o}-offer" }.join(", ")
  end
  
  def check_and_set_api_version_headers
    @api_version = request.headers['API-Version']
    unless %w{ 2.0.0 }.include?(@api_version)
      @api_version = "2.0.0"
      render :action => :invalid_api_version, :status => :not_acceptable
    end
    response.headers['API-Version'] = @api_version
  end
  
  def ensure_api_version(version)
    unless version == @api_version
      @api_version = version
      render :action => :invalid_api_version, :status => :not_acceptable 
      return false
    else
      return true
    end
  end
  
  def web_coupons_index
    @publisher = Publisher.manageable_by(@user).find_by_label(params[:publisher_label]) if params[:publisher_label].present?
    if @publisher
      @request = Api2::WebCouponsRequest::Index.new(:publisher => @publisher, :timestamp_min => params[:timestamp_min])
      if @request.error
        render :action => "error"
      else
        render :action => "web_coupons_index"
      end
    else
      render :nothing => true, :status => :forbidden
    end
  end
  
  def web_coupons_show
    @request = Api2::WebCouponsRequest::Show.new(:user => @user, :id => params[:id])
    if @request.error
      render :action => "error"
    else
      @xhtml = {}.tap do |hash|
        @request.offers.each do |offer|
          response.template.template_format = :html
          xhtml = render_to_string(:partial => "offers/panels/sdcitybeat/xd/offer", :object => offer, :locals => { :publisher => offer.publisher })
          response.template.template_format = :xml

          hash[offer.id] = xhtml
        end
      end
      render :action => "web_coupons_show"
    end
  rescue ActiveRecord::RecordNotFound
    render :nothing => true, :status => :not_found
  end
end

