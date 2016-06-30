class DailyDealVariationsController < ApplicationController
  include Api

  before_filter :user_required, :except => [:index]
  before_filter :set_daily_deal
  before_filter :ensure_current_user_can_manage_daily_deal, :except => [:index]
  before_filter :load_daily_deal_variation_by_id, :only => [:edit, :update, :destroy]
  before_filter :check_and_set_api_version_header_for_json_requests, :only => [:index]


  def index
    respond_to do |format|
      format.json{}
    end
  end

  def new
    @daily_deal_variation = @daily_deal.daily_deal_variations.build({
                              :value_proposition => @daily_deal.value_proposition,
                              :value_proposition_subhead => @daily_deal.value_proposition_subhead,
                              :voucher_headline => @daily_deal.voucher_headline,
                              :value => @daily_deal.value,
                              :price => @daily_deal.price,
                              :terms => @daily_deal.terms(:source),
                              :min_quantity => @daily_deal.min_quantity,
                              :max_quantity => @daily_deal.max_quantity
                            })
    render :edit
  end

  def create
    @daily_deal_variation = @daily_deal.daily_deal_variations.build( params[:daily_deal_variation] )
    if @daily_deal_variation.valid?
      @daily_deal_variation.save
      flash[:notice] = "Variation was successfully created."
      redirect_to edit_daily_deal_path(@daily_deal)
    else
      render :edit
    end
  end

  def edit
  
  end

  def update
    if @daily_deal_variation.update_attributes(params[:daily_deal_variation])
      flash[:notice] = "Variation was successfully updated."
      redirect_to edit_daily_deal_path(@daily_deal)
    else
      render :edit
    end
  end

  def destroy
    begin
      if @daily_deal_variation.delete!
        flash[:notice] = "Variation was successfully removed."
      end
    rescue
      flash[:error] = "We were unable to remove the variation: #{$!}"
    end
    redirect_to edit_daily_deal_path(@daily_deal)
  end

  private

  def set_daily_deal
    @daily_deal = DailyDeal.find(params[:daily_deal_id])
  end

  def ensure_current_user_can_manage_daily_deal
    redirect_to new_session_path and return false unless @daily_deal && current_user.can_manage?(@daily_deal.publisher)
  end

  def load_daily_deal_variation_by_id
    @daily_deal_variation = @daily_deal.daily_deal_variations.find(params[:id])
  end



end
