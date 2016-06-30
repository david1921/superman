class VoiceMessagesController < ApplicationController
  protect_from_forgery :except => :update_one_call_detail_record_sid

  def update_one_call_detail_record_sid
    # using update attribute without validation here because is a record we are just retrieveing from database
    VoiceMessage.find(params[:id]).update_attribute(:call_detail_record_sid, params[:call_detail_record_sid])
    render :text => "ok", :status => 200
  end
end
