class TxtOffersController < ApplicationController
  before_filter :user_required
  before_filter :set_advertiser
  
  def new
    @txt_offer = @advertiser.txt_offers.build(:assign_keyword => true)
    set_crumb_prefix(@advertiser)
    add_crumb "New TXT Coupon"
    render :action => :edit
  end
  
  def create
    @txt_offer = @advertiser.txt_offers.build(params[:txt_offer])
    if @txt_offer.save
      flash[:notice] = "Created TXT coupon for #{@txt_offer.advertiser.name}"
      redirect_to edit_advertiser_path(@advertiser)
    else
      set_crumb_prefix(@advertiser)
      add_crumb "New TXT Coupon"
      render :edit
    end
  end
  
  def edit
    @txt_offer = TxtOffer.find(params[:id])
    set_crumb_prefix(@advertiser)
    add_crumb "Edit TXT Coupon"
  end
  
  def update
    @txt_offer = TxtOffer.find(params[:id])
    
    if @txt_offer.update_attributes(params[:txt_offer])
      flash[:notice] = "Updated TXT coupon #{@txt_offer.keyword}"
      redirect_to edit_advertiser_path(@advertiser)
    else
      set_crumb_prefix(@advertiser)
      add_crumb "Edit TXT Coupon"
      render :edit
    end
  end
  
  def destroy
    @txt_offer = TxtOffer.find(params[:id])
    @txt_offer.delete!
    redirect_to edit_advertiser_path(@advertiser)
  end
  
  private
  
  def set_advertiser
    @advertiser = Advertiser.manageable_by(current_user).find(params[:advertiser_id])
  end

  def set_crumb_prefix(advertiser)
    publisher = advertiser.publisher
    
    if admin? || publishing_group?
      add_crumb "Publishers", publishers_path
    end
    if admin? || publishing_group? || publisher?
      add_crumb publisher.name
      add_crumb "Advertisers", publisher_advertisers_path(publisher)
    end
    add_crumb advertiser.name, edit_advertiser_path(advertiser)
  end
  
end
