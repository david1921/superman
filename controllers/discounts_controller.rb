class DiscountsController < ApplicationController
  if ssl_rails_environment?
    ssl_required :new, :edit
  else
    ssl_allowed  :new, :edit
  end
  ssl_allowed :create, :update, :destroy, :apply

  before_filter :user_required, :except => [:apply]
  before_filter :assign_manageable_publisher, :except => [:apply]
  before_filter :build_paginate_params, :only => [:index]

  def index
    set_crumb_prefix(@publisher)
    @discounts = @publisher.discounts.not_deleted.paginate(@paginate_params)
  end
  
  def new
    @discount = @publisher.discounts.build
    set_crumb_prefix(@publisher)
    add_crumb "New", new_publisher_discount_path(@publisher)
    render :edit
  end
  
  def create
    @discount = @publisher.discounts.build(params[:discount])
    if @discount.save
      redirect_to edit_publisher_url(@publisher)
    else
      set_crumb_prefix(@publisher)
      add_crumb "New", new_publisher_discount_path(@publisher)
      render :edit
    end
  end
  
  def edit
    @discount = @publisher.discounts.not_deleted.find(params[:id])
    set_crumb_prefix(@publisher)
    add_crumb "Edit", edit_publisher_discount_path(@publisher, @discount)
  end
  
  def update
    discount = @publisher.discounts.not_deleted.find(params[:id])
    if discount.update_attributes(params[:discount])
      redirect_to edit_publisher_url(@publisher)
    else
      set_crumb_prefix(@publisher)
      add_crumb "New", new_publisher_discount_path(@publisher)
      render :edit
    end
  end
  
  def destroy
    discount = @publisher.discounts.not_deleted.find(params[:id])
    discount.set_deleted!
    redirect_to edit_publisher_url(@publisher)
  end
  
  def apply
    @publisher = Publisher.find(params[:publisher_id])
    discount_code = Discount.normalize_code(params[:daily_deal_purchase][:discount_code])
    @discount = @publisher.discounts.usable.at_checkout.find_by_code(discount_code)
  end
  
  private

  def build_paginate_params
    params[:per_page] = 10 unless %w{10 100 1000 2000}.include?(params[:per_page])
    params[:search] ||= {}
    @paginate_params = {
      :per_page   => params[:per_page],
      :page       => params[:page],
      :conditions => ( [ "code = ?", params[:search][:code] ] if params[:search][:code])
    }
  end
  
  def assign_manageable_publisher
    @publisher = Publisher.manageable_by(current_user).find(params[:publisher_id])
  end

  def set_crumb_prefix(publisher)
    if admin?
      add_crumb "Publishers", publishers_path
    end
    if publishing_group?
      add_crumb "Publishers", publishing_group_publishers_path(current_user.company)
    end      
    if admin? || publishing_group? || publisher?
      add_crumb publisher.name, edit_publisher_path(publisher)
      add_crumb (@paginate_params ? "Discount Codes" : "Discount Code")
    end
  end
end

