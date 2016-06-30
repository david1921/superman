class LeadsController < ApplicationController
  before_filter  :set_p3p, :only => [ :create ]
  protect_from_forgery :except => :create # FIXME: security

  layout nil

  def create
    @offer = Offer.find(params[:offer_id])
    @lead = @offer.leads.build(params[:lead].try(:merge, { :remote_ip => request.remote_ip }))
    @publisher = @lead.publisher
    @advertiser = Advertiser.find_by_id(params[:advertiser_id])
    partial_path_prefix = @advertiser ? "advertisers/offers/" : "offers/panels/"
    if @lead.save
      render :partial => partial_path_prefix + "confirmation", :offer => @offer, :lead => @lead
    else
      render :partial => partial_path_prefix + @lead.delivery, :offer => @offer, :lead => @lead
    end
  end

  def submitted
    @offer = Offer.find(params[:offer_id])
    @lead = Lead.find(params[:id])
    render(:template => "leads/submitted", :layout => "leads")
  end
end
