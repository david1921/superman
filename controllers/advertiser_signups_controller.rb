class AdvertiserSignupsController < ApplicationController
  def new
    @publisher = Publisher.find(params[:publisher_id])
    if @publisher.self_serve? && @publisher.subscription_rate_schedules.present?
      @advertiser_signup = @publisher.advertiser_signups.new
    else
      render :sorry
    end
  end

  def create
    @publisher = Publisher.find(params[:publisher_id])
    @advertiser_signup = @publisher.advertiser_signups.new(params[:advertiser_signup])

    @advertiser = @publisher.advertisers.new(
                    :name => params[:advertiser_signup][:advertiser_name], 
                    :paid => true, 
                    :subscription_rate_schedule => @publisher.subscription_rate_schedules.first
                  )

    @advertiser_user = User.new(
            :login => @advertiser_signup.email,
            :email => @advertiser_signup.email,
            :password => @advertiser_signup.password,
            :password_confirmation => @advertiser_signup.password_confirmation
          )
    
    @advertiser_signup.advertiser = @advertiser
    @advertiser_signup.user = @advertiser_user

    if @advertiser.valid? && @advertiser_signup.valid? && @advertiser_user.valid?
      Advertiser.transaction do
        @advertiser.save!
        @advertiser_user.save!
        UserCompany.create!(:user => @advertiser_user, :company => @advertiser)
        @advertiser_signup.save!
      end
      session[:user_id] = @advertiser_user.id
      redirect_to edit_advertiser_path(@advertiser)
    else
      render :new
    end
  end
end
