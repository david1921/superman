class CallDetailRecordsController < ApplicationController
  protect_from_forgery :except => :create

  def create
    CallDetailRecord.create! params.except(:controller, :action)
    render :text => "ok", :status => 200
  end
end
