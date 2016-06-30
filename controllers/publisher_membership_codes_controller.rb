class PublisherMembershipCodesController < ApplicationController

  before_filter :admin_privilege_required, :only => :index

  def index
    respond_to do |format|
      format.xml {
        render :xml => PublisherMembershipCode.all
      }
    end
  end

end