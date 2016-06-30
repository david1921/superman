class PasswordResetsController < ApplicationController
  before_filter :set_user_from_perishable_token

  def create
    email = params[:email].try(:strip)

    if email.blank?
      flash.now[:warn] = "Please provide an email address."
      render :new
    elsif @user = User.find_by_email(email)
      if !@user.access_locked?
        flash.now[:notice] = "Password reset email sent."
        @user.deliver_password_reset_instructions!
      else
        flash.now[:warn] = "Sorry, that account is locked.  Please contact an administrator."
        render :new
      end
    else
      if Analog::Util::EmailValidator.new.valid_email?(email)
        flash.now[:warn] = "Sorry, no user was found with the provided email address."
      else
        flash.now[:warn] = "The provided email address was invalid."
      end
      render :new
    end
  end
  
  def update
    @user.password = params[:user][:password]
    @user.password_confirmation = params[:user][:password_confirmation]
    @user.require_password = true
    if @user.save
      set_up_session(@user)
      flash[:notice] = "Password successfully updated"
      redirect_to root_path
    else
      render :edit
    end
  end
  
  private
  
  def set_user_from_perishable_token
    @user = User.find_by_perishable_token(params[:id])
    unless @user
      flash[:notice] = "We're sorry, but we could not locate your account"
      redirect_to root_url
    end
  end
end
