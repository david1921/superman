module Syndication
  class AgreementsController < ApplicationController
    before_filter :require_authentication
    
    def new
      @agreement = Agreement.new
      render :edit
    end

    def create
      @agreement = Agreement.new(params[:syndication_agreement])
      if @agreement.save
        flash[:notice] = "Thank you"
        redirect_to syndication_agreement_path(@agreement)
      else
        render :edit
      end
    end
    
    def show
      @agreement = Agreement.find(params[:id])
    end


    private

    def require_authentication
      authenticate_or_request_with_http_basic do |user_name, password|
        user_name == "contract" && password == "analog"
      end
    end
  end
end
