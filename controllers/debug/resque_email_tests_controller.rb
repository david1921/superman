module Debug
  class ResqueEmailTestsController < ApplicationController

    before_filter :admin_privilege_required

    def create
      email_address = params["email_address"]
      Resque.enqueue(Debug::SimpleTestEmailSender, email_address)
      flash[:notice] = "Email queued for sending to #{email_address}"
      redirect_to :action => "new"
    end

  end
end