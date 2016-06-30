class PushNotificationDevicesController < ApplicationController
  include Api
  
  ssl_allowed :create, :destroy

  skip_before_filter :verify_authenticity_token
  before_filter :assign_publisher
  before_filter :check_and_set_api_version_header
  
  layout false
  
  def create
    respond_to do |format|
      format.json do
        @push_notification_device = PushNotificationDevice.enroll(@publisher, params[:device][:token])
        if @push_notification_device.changed?
          render :status => :conflict, :json => { :errors => @push_notification_device.errors.full_messages }
        else
          render :status => :ok
        end
      end
    end
  end

  def destroy
    respond_to do |format|
      format.json do
        PushNotificationDevice.reject(@publisher, params[:id])
        render :nothing => true, :status => :ok
      end
    end
  end
  
  private
  
  def assign_publisher
    @publisher = Publisher.find(params[:publisher_id])
  end
end
