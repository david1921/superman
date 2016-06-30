class UserLocksController < ApplicationController
  before_filter :set_user, :only => [:lock, :unlock]
  before_filter :full_admin_privilege_required, :only => [:lock, :unlock], :if => :managing_a_non_consumer?
  before_filter :manage_consumer_privilege_required, :only => [:lock, :unlock], :if => :managing_a_consumer?
  ssl_allowed :lock, :unlock, :index

  def index
    full_admin_privilege_required
    @locked_users = User.locked.paginate(:page => page_param, :per_page => per_page_param)
  end

  def lock
    @user.lock_access!(current_user)
    flash[:notice] = I18n.translate(:lock_successful, :scope => :user_locks_controller)
    redirect_to :back
  end

  def unlock
    @user.unlock_access!(current_user)
    flash[:notice] = I18n.translate(:unlock_successful, :scope => :user_locks_controller)
    redirect_to :back
  end

  private

  def page_param
    params[:page] || 1
  end

  def per_page_param
    params[:per_page] || 50
  end

  def manage_consumer_privilege_required
    raise "expected @user to be a consumer, got #{@user.inspect}" unless @user.is_a?(Consumer)

    unless logged_in?
      access_denied 
      return
    end

    unless current_user.can_manage_consumer?(@user)
      access_forbidden 
      return
    end
  end

  def full_admin_privilege_required
    unless logged_in?
      access_denied
      return
    end

    unless full_admin?
      access_forbidden
      return
    end
  end
 
  def managing_a_non_consumer?
    !managing_a_consumer?
  end

  def managing_a_consumer?
    raise "unable to determine whether @user is a consumer: @user is blank. maybe you meant to set @user in a before_filter first?" if @user.blank?
    @user.is_a?(Consumer)
  end

  def set_user
    @user = User.find(params[:id])
  end
end
