class MobilePhonesController < ApplicationController
  layout "txt411/application"

  def new
    @mobile_phone = MobilePhone.new
  end

  def create
    @mobile_phone = MobilePhone.from_params(params[:mobile_phone].merge(:opt_out => true))
    if @mobile_phone.valid?
      redirect_to opt_out_path(@mobile_phone) and return
    else
      render :action => :new
    end
  end

  def show
    @mobile_phone = MobilePhone.find(params[:id])
  end
end
