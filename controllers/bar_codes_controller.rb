class BarCodesController < ApplicationController
  
  before_filter :set_daily_deal_purchase
  before_filter :set_daily_deal_certificate

  def show
    respond_to do |format|
      format.jpg do
        file = if @daily_deal_certificate.voucher_has_qr_code?
          qr_code_options = { :level => 3, :module_size => 8, :output_format => :jpg, :keep_file => true }
          @daily_deal_certificate.with_qr_code_image(@daily_deal_certificate.serial_number, qr_code_options)
        else
          bar_code_number = @daily_deal_certificate.bar_code || @daily_deal_certificate.serial_number
          @daily_deal_certificate.with_bar_code_image(bar_code_number, :keep_jpg => true)
        end
        send_file file, :disposition => 'inline'
      end
    end
  end
  
  private
  
  def set_daily_deal_purchase
    @daily_deal_purchase = DailyDealPurchase.find_by_uuid params[:daily_deal_purchase_id]
    unless @daily_deal_purchase
      render :nothing => true, :status => :not_found
    end
  end
  
  def set_daily_deal_certificate
    @daily_deal_certificate = @daily_deal_purchase.daily_deal_certificates.find_by_serial_number params[:id]
    unless @daily_deal_certificate
      render :nothing => true, :status => :not_found
    end
  end

end
