class GiftCertificatesController < ApplicationController
  include Advertisers::Breadcrumbs
  include Publishers::Themes
    
  before_filter :user_required, :only => [:index, :new, :create, :edit, :update, :destroy, :preview, :preview_pdf]
  before_filter :set_advertiser, :only => [:index, :new, :create, :edit, :update, :destroy]
  
  protect_from_forgery :except => :redeem
  
  def public_index
    load_publisher_by_label
    @return_url = request.headers['HTTP_REFERER']
    if params[:gift_certificate_id]
      @gift_certificates = [ @publisher.gift_certificates.find_by_id(params[:gift_certificate_id]) ]
    else
      @gift_certificates = @publisher.gift_certificates.active.available.recent
    end
    @gift_certificates.each(&:record_impression) 
    @paypal_configuration = paypal_configuration_for_publisher(@publisher)
    
    # TODO: if other publishers want to start showing upcoming
    # deal certificates, then we should move this to the model.
    # currently this is hard coded to grab the gc at the
    # start of the week
    unless @publisher.theme == 'withtheme'
      if @publisher.label == 'wor710'
        # shows the upcoming gc on thursday, 1 day before friday it goes live.
        @upcoming_gift_certificates = @publisher.gift_certificates.available.starting_on(Time.zone.now+1.day) 
      end
    
      if params[:layout] == 'iframe'
        render :layout => "gift_certificates/public_index"
      else
        render :layout => layout_for_publisher( @publisher ), :template => template_for_publisher(@publisher, "public_index")
      end
    else
      render with_theme(:layout => "gift_certificates/public_index", :template => "gift_certificates/public_index")
    end
  end  
  
  def show
    @gift_certificate = GiftCertificate.find(params[:id])
    @gift_certificate.record_impression
    @return_url = request.headers['HTTP_REFERER']
    @paypal_configuration = paypal_configuration_for_publisher(@gift_certificate.publisher)
    
    respond_to do |format|
      format.html
      format.js { render :layout => false }
    end
  end
  
  def preview
    @gift_certificate = GiftCertificate.find(params[:id])
    @advertiser = Advertiser.manageable_by(current_user).find(@gift_certificate.advertiser) # authorization check
    return access_denied unless @advertiser
    @publisher = @gift_certificate.publisher
    @gift_certificates = [@gift_certificate]
    render :action => :public_index, :layout => 'gift_certificates/public_index'
  end
  
  def preview_pdf
    @gift_certificate = GiftCertificate.find(params[:id])
    @advertiser = Advertiser.manageable_by(current_user).find(@gift_certificate.advertiser) # authorization check
    return access_denied unless @advertiser
    send_data @gift_certificate.to_preview_pdf, :filename => "gift_certificate.pdf", :type => "application/pdf"
  end
  
  def new
    @gift_certificate = @advertiser.gift_certificates.build
    set_crumb_prefix(@advertiser)
    add_crumb "New Deal Certificate", new_gift_certificate_path(@advertiser)
    render :edit
  end
  
  def create
    @gift_certificate = @advertiser.gift_certificates.build(params[:gift_certificate])
    if @gift_certificate.save
      flash[:notice] = "Created deal certificate for #{@advertiser.name}"
      redirect_to edit_advertiser_path(@advertiser)
    else
      set_crumb_prefix(@advertiser)
      add_crumb "New Deal Certificate", new_gift_certificate_path(@advertiser)
      render :edit
    end
  end 
  
  def edit
    @gift_certificate = @advertiser.gift_certificates.find( params[:id] )
    set_crumb_prefix(@advertiser)
    add_crumb "Edit Deal Certificate", edit_advertiser_gift_certificate_path(@advertiser, @gift_certificate)
  end
  
  def update
    @gift_certificate = @advertiser.gift_certificates.find( params[:id] )
    if @gift_certificate.update_attributes( params[:gift_certificate] )
      flash[:notice] = "Deal Certificate was updated."
      redirect_to edit_advertiser_path( @advertiser )
    else
      set_crumb_prefix( @advertiser )
      add_crumb "Edit Deal Certificate", edit_advertiser_gift_certificate_path( @advertiser, @gift_certificate )
      render :edit
    end
  end
  
  def destroy
    @gift_certificate = @advertiser.gift_certificates.find( params[:id] )
    if @gift_certificate.delete!
      flash[:notice] = "Deal Certificate has been deleted."
    else
      flash[:error] = "We were unable to delete deal certificate."
    end
    redirect_to edit_advertiser_path( @advertiser )      
  end
  
  def twitter
    gift_certificate = GiftCertificate.find(params[:id])
    gift_certificate.record_click "twitter"
    redirect_to "http://twitter.com/?status=#{CGI.escape(gift_certificate.twitter_status).gsub('+', '%20')}"
  end
  
  def facebook
    gift_certificate = GiftCertificate.find(params[:id])
    gift_certificate.record_click "facebook"
    
    gift_certificate_url = public_gift_certificates_url(gift_certificate.publisher.label, :gift_certificate_id => gift_certificate.to_param, :v => gift_certificate.updated_at.to_i)
    facebook_url         = gift_certificate.facebook_url(gift_certificate_url, params[:popup].present?)

    redirect_to facebook_url
  end

  private
  
  def load_publisher_by_label
    @publisher = Publisher.find_by_label!(params[:label])
  end   
  
  def set_advertiser
    @advertiser = Advertiser.manageable_by(current_user).find(params[:advertiser_id])
  end

  def paypal_configuration_for_publisher(publisher)
    if publisher.enable_paypal_buy_now?
      paypal_configuration = PaypalConfiguration.for_currency_code(publisher.currency_code) 
      paypal_configuration.setup_paypal_notification!
      paypal_configuration
    end
  end
end
